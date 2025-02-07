// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ISendEarn} from "./ISendEarn.sol";

interface ISendEarnFactory {
    /// @notice The address of the MetaMorpho contract that SendEarn vaults uses.
    function META_MORPHO() external view returns (address);

    /// @notice Whether a SendEarn vault was created with the factory.
    function isSendEarn(address target) external view returns (bool);

    /// @notice Creates a new SendEarn vault.
    /// @param initialOwner The owner of the vault.
    /// @param asset The address of the underlying asset.
    /// @param name The name of the vault.
    /// @param symbol The symbol of the vault.
    /// @param salt The salt to use for the SendEarn vault's CREATE2 address.
    function createSendEarn(
        address initialOwner,
        address asset,
        string memory name,
        string memory symbol,
        bytes32 salt
    ) external returns (ISendEarn metaMorpho);
}
