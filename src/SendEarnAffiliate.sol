// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {ISendEarnAffiliate, IPartnerSplitConfig} from "./interfaces/ISendEarnAffiliate.sol";
import {IERC20, IERC4626, Math, SafeERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

/// @notice Affiliate contract for splitting earnings between platform and an affiliate.
contract SendEarnAffiliate is ISendEarnAffiliate {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /* IMMUTABLES */

    /// @inheritdoc ISendEarnAffiliate
    IPartnerSplitConfig public immutable override splitConfig;

    /// @inheritdoc ISendEarnAffiliate
    address public immutable override affiliate;

    /// @inheritdoc ISendEarnAffiliate
    IERC4626 public immutable override platformVault;

    /* STATE */

    /// @inheritdoc ISendEarnAffiliate
    IERC4626 public override payVault;

    /* CONSTRUCTOR */

    constructor(address _affiliate, address _splitConfig, address _payVault, address _platformVault) {
        if (_affiliate == address(0)) revert Errors.ZeroAddress();
        if (_splitConfig == address(0)) revert Errors.ZeroAddress();
        if (_payVault == address(0)) revert Errors.ZeroAddress();
        if (_platformVault == address(0)) revert Errors.ZeroAddress();
        affiliate = _affiliate;
        splitConfig = IPartnerSplitConfig(_splitConfig);
        _setPayVault(_payVault);
        platformVault = IERC4626(_platformVault);
        if (platformVault.asset() != payVault.asset()) revert Errors.AssetMismatch();
    }

    /* EXTERNAL */

    /// @inheritdoc ISendEarnAffiliate
    function pay(IERC4626 vault) external virtual {
        payWithAmount(vault, vault.maxRedeem(address(this)));
    }

    /// @inheritdoc ISendEarnAffiliate
    function payWithAmount(IERC4626 vault, uint256 amount) public virtual {
        IERC20 asset = IERC20(vault.asset());
        if (address(asset) != address(payVault.asset())) revert Errors.AssetMismatch();
        if (amount == 0) revert Errors.ZeroAmount();

        // convert to the underlying asset
        uint256 assets = vault.redeem(amount, address(this), address(this));

        // calculate the split
        uint256 split = splitConfig.split();
        uint256 platformSplit = assets.mulDiv(split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = assets.mulDiv(Constants.SPLIT_TOTAL - split, Constants.SPLIT_TOTAL);

        // transfer the split to the platform and affiliate
        platformVault.deposit(platformSplit, splitConfig.platform());
        payVault.deposit(affiliateSplit, affiliate);

        emit Events.AffiliatePay(msg.sender, address(vault), address(asset), assets, platformSplit, affiliateSplit);
    }

    /// @inheritdoc ISendEarnAffiliate
    function setPayVault(address vault) external onlyAffiliate {
        if (vault == address(0)) revert Errors.ZeroAddress();
        if (vault == address(payVault)) revert Errors.AlreadySet();

        IERC4626 newPayVault = IERC4626(vault);
        if (newPayVault.asset() != payVault.asset()) revert Errors.AssetMismatch();

        _setPayVault(vault);
    }

    /* INTERNAL */

    modifier onlyAffiliate() {
        if (msg.sender != affiliate) revert Errors.UnauthorizedAffiliate();
        _;
    }

    function _setPayVault(address newPayVault) internal {
        payVault = IERC4626(newPayVault);

        IERC20 asset = IERC20(payVault.asset());
        asset.forceApprove(newPayVault, type(uint256).max);

        emit Events.SetPayVault(newPayVault);
    }
}
