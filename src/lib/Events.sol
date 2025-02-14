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
    /// @notice Emitted when the affiliate address is set to `newAffiliate`.
    event SetAffiliate(address indexed newAffiliate);
    /// @notice Emitted when the platform address is set to `newPlatform`.
    event SetPlatform(address indexed newPlatform);
    /// @notice Emitted when the affiliate pays out the earnings.
    /// @param caller The caller of the function.
    /// @param sendEarnVault The address of the SendEarn vault.
    /// @param asset The address of the underlying asset.
    /// @param amount The total amount of tokens paid out to the platform and affiliate.
    /// @param platformSplit The portion of tokens paid out to the platform.
    /// @param affiliateSplit The portion of tokens paid out to the affiliate.
    event AffiliatePay(
        address indexed caller,
        address indexed sendEarnVault,
        address indexed asset,
        uint256 amount,
        uint256 platformSplit,
        uint256 affiliateSplit
    );
    /// @notice Emitted when a new SendEarn vault is created.
    /// @param sendEarn The address of the SendEarn vault.
    /// @param caller The caller of the function.
    /// @param metaMorpho The address of the MetaMorpho contract.
    /// @param initialOwner The initial owner of the SendEarn vault.
    /// @param feeRecipient The address of the fee recipient.
    /// @param collections The address of the collections.
    /// @param fee The fee.
    /// @param salt The salt used for the SendEarn vault's CREATE2 address.
    event CreateSendEarn(
        address indexed sendEarn,
        address indexed caller,
        address initialOwner,
        address indexed metaMorpho,
        address feeRecipient,
        address collections,
        uint96 fee,
        bytes32 salt
    );
    /// @notice Emitted when the split is set to `newSplit`.
    event SetSplit(uint256 newSplit);
    /// @notice Emitted when a new affiliate is created.
    /// @param affiliate The address of the affiliate.
    /// @param sea The address of the SendEarnAffiliate contract.
    event NewAffiliate(address affiliate, address sea);
}
