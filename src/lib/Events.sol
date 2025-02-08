// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

library Events {
    /// @notice Emitted when fee is set to `newFee`.
    event SetFee(address indexed caller, uint256 newFee);
    /// @notice Emitted when fee recipient is set to `newFeeRecipient`.
    event SetFeeRecipient(address indexed newFeeRecipient);
    /// @notice Emitted when collections address is set to `newCollections`.
    event SetCollections(address indexed newCollections);
    /// @notice Emitted when tokens are sent to the collections address.
    event Collect(address indexed caller, address indexed token, uint256 amount);
    /// @notice Emitted when interest are accrued.
    /// @param newTotalAssets The assets of the vault after accruing the interest but before the interaction.
    /// @param feeShares The shares minted to the fee recipient.
    event AccrueInterest(uint256 newTotalAssets, uint256 feeShares);
    /// @notice Emitted when the last total assets is updated to `updatedTotalAssets`.
    event UpdateLastTotalAssets(uint256 updatedTotalAssets);
    /// @notice Emitted when a new SendEarn vault is created.
    /// @param sendEarn The address of the SendEarn vault.
    /// @param caller The caller of the function.
    /// @param initialOwner The initial owner of the SendEarn vault.
    /// @param asset The address of the underlying asset.
    /// @param name The name of the SendEarn vault.
    /// @param symbol The symbol of the SendEarn vault.
    /// @param salt The salt used for the SendEarn vault's CREATE2 address.
    event CreateSendEarn(
        address indexed sendEarn,
        address indexed caller,
        address initialOwner,
        address indexed asset,
        string name,
        string symbol,
        bytes32 salt
    );
}
