// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, IERC4626, ERC20, ERC4626, Math, SafeERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {SafeCast} from "openzeppelin-contracts/utils/math/SafeCast.sol";
import {UtilsLib} from "morpho-blue/libraries/UtilsLib.sol";

/// @title SendEarn
/// @author Send Squad
/// @notice ERC4626 vault allowing users to deposit USDC to earn yield through Morpho & Morpho
contract SendEarn is ERC4626, ERC20Permit, Ownable2Step {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /* IMMUTABLES */

    /// @notice The Morpho vault contract
    IERC4626 public immutable MORPHO;

    /// @notice OpenZeppelin decimals offset used by the ERC4626 implementation
    uint8 public immutable DECIMALS_OFFSET;

    /* STORAGE */

    /// @notice Fee configuration for the vault
    struct FeeConfig {
        // Platform fee basis points
        uint256 platformFee; // TODO: Define max bounds
        // Referral fee basis points
        uint256 referralFee; // TODO: Define max bounds
        // Fee recipient
        address feeRecipient;
    }

    /// @notice Tracks referral relationships
    mapping(address user => address referrer) public referrers;

    // TODO: Add fee tracking/accounting variables

    /* EVENTS */

    // TODO: Add events

    /* ERRORS */

    // TODO: Add errors

    /* CONSTRUCTOR */

    constructor(
        address owner,
        address morphoVault,
        address asset,
        string memory _name,
        string memory _symbol
    )
        ERC4626(IERC20(asset))
        ERC20Permit(_name)
        ERC20(_name, _symbol)
        Ownable(owner)
    {
        MORPHO = IERC4626(morphoVault);
        DECIMALS_OFFSET = uint8(
            UtilsLib.zeroFloorSub(uint256(18), IERC20Metadata(asset).decimals())
        );

        // TODO: Initialize other state variables

        // Approve Morpho vault to spend our underlying asset
        IERC20(asset).approve(morphoVault, type(uint256).max);
    }

    /* Referrer (Public) */

    /// @notice Sets the referrer of the sender
    function setReferrer(address referrer) external {
        referrers[msg.sender] = referrer;
    }

    /* ERC4626 (PUBLIC) */

    /// @inheritdoc IERC20Metadata
    function decimals() public view override(ERC20, ERC4626) returns (uint8) {
        return ERC4626.decimals();
    }

    function totalAssets() public view override returns (uint256) {
        require(false, "TODO: totalAssets");
    }

    /* ERC4626 (INTERNAL) */

    /// @inheritdoc ERC4626
    function _decimalsOffset() internal view override returns (uint8) {
        return DECIMALS_OFFSET;
    }

    /// @inheritdoc ERC4626
    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        require(false, "TODO: _convertToShares");
    }

    /// @inheritdoc ERC4626
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        require(false, "TODO: _convertToAssets");
    }

    /// @inheritdoc ERC4626
    /// @dev Accepts assets from `msg.sender`, deposits them into Morpho, and mints shares to `receiver`.
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        // 1. Transfer assets from caller
        super._deposit(caller, receiver, assets, shares);
        // 2. Deposit into Morpho
        MORPHO.deposit(assets, address(this));
        // 3. Calculate and track fees
        require(false, "TODO: track fees");
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
        // 2. Withdraw from Morpho
        // 3. Calculate and distribute fees
        // 4. Transfer assets to receiver
    }
}
