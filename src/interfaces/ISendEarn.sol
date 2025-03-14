// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IOwnable} from "./IOwnable.sol";
import {IERC4626} from "openzeppelin-contracts/interfaces/IERC4626.sol";
import {IERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IFeeConfig} from "./IFeeConfig.sol";

interface IMulticall {
    function multicall(bytes[] calldata) external returns (bytes[] memory);
}

interface ISendEarnBase {
    /// @notice The underlying vault contract
    function VAULT() external view returns (IERC4626);

    /// @notice OpenZeppelin decimals offset used by the ERC4626 implementation
    function DECIMALS_OFFSET() external view returns (uint8);

    /// @notice The fee recipient
    function feeRecipient() external view returns (address);

    /// @notice The collection address, all ERC20 tokens on this contract will be sent to this address
    function collections() external view returns (address);

    /// @notice The last total assets
    function lastTotalAssets() external view returns (uint256);

    /// @notice Sets the fee recipient address
    function setFeeRecipient(address newFeeRecipient) external;

    /// @notice Sets the collections address
    function setCollections(address newCollections) external;

    /// @notice Accrues the fee and mints fee shares to the fee recipient
    function accrueFee() external;

    /// @notice Transfers ERC20 tokens to the collections address
    function collect(address token) external;
}

/// @title ISendEarn
/// @author Send Squad
/// @notice ERC4626 vault interface allowing users to deposit assets to earn yield through an underlying vault
interface ISendEarn is ISendEarnBase, IERC4626, IERC20Permit, IOwnable, IMulticall, IFeeConfig {
// solhint-disable-previous-line no-empty-blocks
}
