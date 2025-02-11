// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {ISendEarnAffiliate, ISplitConfig} from "./interfaces/ISendEarnAffiliate.sol";
import {IERC20, IERC4626, Math, SafeERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {UtilsLib} from "morpho-blue/libraries/UtilsLib.sol";
import {ISendEarn} from "./interfaces/ISendEarn.sol";

/// @notice Affiliate contract for splitting earnings between platform and an affiliate.
contract SendEarnAffiliate is ISendEarnAffiliate {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using UtilsLib for uint256;

    /* IMMUTABLES */

    /// @inheritdoc ISendEarnAffiliate
    ISplitConfig public immutable override splitConfig;

    /// @inheritdoc ISendEarnAffiliate
    address public immutable override affiliate;

    /// @inheritdoc ISendEarnAffiliate
    IERC4626 public immutable override payVault;

    /* CONSTRUCTOR */

    constructor(address _affiliate, address _splitConfig, address _payVault) {
        if (_affiliate == address(0)) revert Errors.ZeroAddress();
        if (_splitConfig == address(0)) revert Errors.ZeroAddress();
        if (_payVault == address(0)) revert Errors.ZeroAddress();
        affiliate = _affiliate;
        splitConfig = ISplitConfig(_splitConfig);
        payVault = IERC4626(_payVault);
        IERC20 asset = IERC20(payVault.asset());
        asset.forceApprove(_payVault, type(uint256).max);
    }

    /// @inheritdoc ISendEarnAffiliate
    function pay(IERC4626 vault) external {
        IERC20 asset = IERC20(vault.asset());
        if (address(asset) != address(payVault.asset())) revert Errors.AssetMismatch();
        // find the amount of tokens to pay
        uint256 amount = vault.balanceOf(address(this));
        if (amount == 0) revert Errors.ZeroAmount();

        // convert to the underlying asset
        uint256 assets = vault.redeem(amount, address(this), address(this));

        // calculate the split
        uint256 split = splitConfig.split();
        uint256 platformSplit = assets.mulDiv(split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = assets.mulDiv(Constants.SPLIT_TOTAL - split, Constants.SPLIT_TOTAL);

        // transfer the split to the platform and affiliate
        payVault.deposit(platformSplit, splitConfig.platform());
        payVault.deposit(affiliateSplit, affiliate);

        emit Events.AffiliatePay(msg.sender, address(vault), address(asset), assets, platformSplit, affiliateSplit);
    }
}
