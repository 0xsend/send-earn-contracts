// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC4626, IERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";
import {UtilsLib} from "morpho-blue/libraries/UtilsLib.sol";

/// @title SendEarn
/// @author Send Squad
/// @notice ERC4626 vault allowing users to deposit USDC to earn yield through Moonwell & Morpho
contract SendEarn is ERC4626, Ownable2Step {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /* IMMUTABLES */

    /// @notice The Moonwell USDC vault contract
    IERC4626 public immutable MOONWELL_VAULT;

    /// @notice OpenZeppelin decimals offset used by the ERC4626 implementation
    uint8 public immutable DECIMALS_OFFSET;

    /* STORAGE */

    /// @notice Fee configuration for the vault
    struct FeeConfig {
        uint256 platformFee; // TODO: Define max bounds
        uint256 referralFee; // TODO: Define max bounds
        address feeRecipient;
    }

    /// @notice Tracks referral relationships
    mapping(address user => address referrer) public referrals;

    // TODO: Add fee tracking/accounting variables

    /* EVENTS */

    // TODO: Add events

    /* ERRORS */

    // TODO: Add errors

    /* CONSTRUCTOR */

    constructor(
        address owner,
        address moonwellVault,
        address asset,
        string memory name,
        string memory symbol
    ) ERC4626(IERC20(asset)) ERC20(name, symbol) Ownable(owner) {
        MOONWELL_VAULT = IERC4626(moonwellVault);
        DECIMALS_OFFSET = uint8(
            UtilsLib.zeroFloorSub(uint256(18), IERC20Metadata(asset).decimals())
        );

        // TODO: Initialize other state variables

        // Approve Moonwell vault to spend our underlying asset
        IERC20(asset).approve(moonwellVault, type(uint256).max);
    }

    /* EXTERNAL FUNCTIONS */

    // TODO: Add deposit with referral function

    /* INTERNAL FUNCTIONS */

    // TODO: Add fee calculation helpers
    // TODO: Add yield tracking logic
    // TODO: Add referral fee distribution logic

    /* ERC4626 OVERRIDES */

    function totalAssets() public view override returns (uint256) {
        // TODO: Implement based on Moonwell vault shares
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        // TODO: Implement deposit logic including:
        // 1. Transfer assets from caller
        // 2. Deposit into Moonwell
        // 3. Calculate and track fees
        // 4. Mint shares
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        // TODO: Implement withdrawal logic including:
        // 1. Burn shares
        // 2. Withdraw from Moonwell
        // 3. Calculate and distribute fees
        // 4. Transfer assets to receiver
    }
}
