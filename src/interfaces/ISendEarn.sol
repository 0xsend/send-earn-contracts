// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

interface ISendEarn {
    function setFeeRecipient(address newFeeRecipient) external;
    /// @notice Claims MetaMorpho rewards for the vault
    function claimRewards(address receiver) external;
}
