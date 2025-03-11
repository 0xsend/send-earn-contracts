// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Utils} from "./lib/Utils.sol";
import {ERC20Permit} from "openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    IERC20,
    IERC4626,
    ERC20,
    ERC4626,
    Math,
    SafeERC20
} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable2Step.sol";
import {Multicall} from "../lib/openzeppelin-contracts/contracts/utils/Multicall.sol";
import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {ISendEarnBase} from "./interfaces/ISendEarn.sol";
import {IFeeConfig} from "./interfaces/IFeeConfig.sol";
import {Platform} from "./Platform.sol";

uint256 constant WAD = 1e18;

/// @title SendEarn
/// @author Send Squad
/// @notice ERC4626 vault allowing users to deposit assets to earn yield through an underlying vault
contract SendEarn is ERC4626, ERC20Permit, Platform, ISendEarnBase, Multicall, IFeeConfig {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using Utils for uint256;

    /* IMMUTABLES */

    /// @notice The underlying vault contract
    IERC4626 public immutable VAULT;

    /// @notice OpenZeppelin decimals offset used by the ERC4626 implementation
    uint8 public immutable DECIMALS_OFFSET;

    /* STORAGE */

    /// @notice the current fee
    uint96 public override fee;

    /// @notice The fee recipient
    address public feeRecipient;

    /// @notice The collection address, all ERC20 tokens on this contract will be sent to this address
    address public collections;

    /// @notice The last total assets
    uint256 public lastTotalAssets;

    /* CONSTRUCTOR */

    constructor(
        address _platform,
        address owner,
        address vault,
        address asset,
        string memory _name,
        string memory _symbol,
        address _feeRecipient,
        address _collections,
        uint96 _fee
    ) ERC4626(IERC20(asset)) ERC20Permit(_name) ERC20(_name, _symbol) Platform(_platform) Ownable(owner) {
        if (vault == address(0)) revert Errors.ZeroAddress();
        if (_feeRecipient != address(0)) feeRecipient = _feeRecipient;
        if (_collections != address(0)) collections = _collections;
        if (_fee > Constants.MAX_FEE) revert Errors.MaxFeeExceeded();
        if (_fee != 0 && _feeRecipient == address(0)) revert Errors.ZeroFeeRecipient();

        fee = _fee;
        VAULT = IERC4626(vault);
        DECIMALS_OFFSET = uint8(uint256(18).zeroFloorSub(IERC20Metadata(asset).decimals()));

        IERC20(asset).forceApprove(vault, type(uint256).max);
    }

    /* OWNER ONLY */

    /// @inheritdoc IFeeConfig
    function setFee(uint256 newFee) external onlyOwner {
        if (newFee == fee) revert Errors.AlreadySet();
        if (newFee > Constants.MAX_FEE) revert Errors.MaxFeeExceeded();
        if (newFee != 0 && feeRecipient == address(0)) revert Errors.ZeroFeeRecipient();

        // Accrue fee using the previous fee set before changing it.
        accrueFee();

        // Safe "unchecked" cast because newFee <= MAX_FEE.
        fee = uint96(newFee);

        emit Events.SetFee(_msgSender(), fee);
    }

    /// @inheritdoc ISendEarnBase
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        if (newFeeRecipient == address(0)) revert Errors.ZeroAddress();
        feeRecipient = newFeeRecipient;

        emit Events.SetFeeRecipient(newFeeRecipient);
    }

    /// @inheritdoc ISendEarnBase
    function setCollections(address newCollections) external onlyOwner {
        if (newCollections == address(0)) revert Errors.ZeroAddress();
        collections = newCollections;

        emit Events.SetCollections(newCollections);
    }

    /* EXTERNAL */

    /// @inheritdoc ISendEarnBase
    function collect(address token) external {
        if (collections == address(0)) revert Errors.ZeroAddress();

        uint256 amount = IERC20(token).balanceOf(address(this));

        IERC20(token).safeTransfer(collections, amount);

        emit Events.Collect(_msgSender(), token, amount);
    }

    /// @inheritdoc ISendEarnBase
    function accrueFee() public {
        _updateLastTotalAssets(_accrueFee());
    }

    /* ERC4626 (PUBLIC) */

    /// @inheritdoc IERC20Metadata
    function decimals() public view override(ERC20, ERC4626) returns (uint8) {
        return ERC4626.decimals();
    }

    /// @inheritdoc IERC4626
    /// @dev Warning: May be higher than the actual max deposit due to duplicate markets in the supplyQueue.
    function maxDeposit(address) public view override returns (uint256) {
        return _maxDeposit();
    }

    /// @inheritdoc IERC4626
    /// @dev Warning: May be higher than the actual max mint due to duplicate markets in the supplyQueue.
    function maxMint(address) public view override returns (uint256) {
        uint256 suppliable = _maxDeposit();

        return _convertToShares(suppliable, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    /// @dev Warning: May be lower than the actual amount of assets that can be withdrawn by `owner` due to conversion
    /// roundings between shares and assets.
    function maxWithdraw(address owner) public view override returns (uint256 assets) {
        (assets,,) = _maxWithdraw(owner);
    }

    /// @inheritdoc IERC4626
    /// @dev Warning: May be lower than the actual amount of shares that can be redeemed by `owner` due to conversion
    /// roundings between shares and assets.
    function maxRedeem(address owner) public view override returns (uint256) {
        (uint256 assets, uint256 newTotalSupply, uint256 newTotalAssets) = _maxWithdraw(owner);

        return _convertToSharesWithTotals(assets, newTotalSupply, newTotalAssets, Math.Rounding.Floor);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        uint256 newTotalAssets = _accrueFee();

        // Update `lastTotalAssets` to avoid an inconsistent state in a re-entrant context.
        // It is updated again in `_deposit`.
        lastTotalAssets = newTotalAssets;

        shares = _convertToSharesWithTotals(assets, totalSupply(), newTotalAssets, Math.Rounding.Floor);

        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        uint256 newTotalAssets = _accrueFee();

        // Update `lastTotalAssets` to avoid an inconsistent state in a re-entrant context.
        // It is updated again in `_deposit`.
        lastTotalAssets = newTotalAssets;

        assets = _convertToAssetsWithTotals(shares, totalSupply(), newTotalAssets, Math.Rounding.Ceil);

        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        uint256 newTotalAssets = _accrueFee();

        // Do not call expensive `maxWithdraw` and optimistically withdraw assets.

        shares = _convertToSharesWithTotals(assets, totalSupply(), newTotalAssets, Math.Rounding.Ceil);

        // `newTotalAssets - assets` may be a little off from `totalAssets()`.
        _updateLastTotalAssets(newTotalAssets.zeroFloorSub(assets));

        _withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        uint256 newTotalAssets = _accrueFee();

        // Do not call expensive `maxRedeem` and optimistically redeem shares.

        assets = _convertToAssetsWithTotals(shares, totalSupply(), newTotalAssets, Math.Rounding.Floor);

        // `newTotalAssets - assets` may be a little off from `totalAssets()`.
        _updateLastTotalAssets(newTotalAssets.zeroFloorSub(assets));

        _withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view override returns (uint256 assets) {
        // Returns the total assets held in the underlying vault (with interest)
        assets = VAULT.convertToAssets(VAULT.balanceOf(address(this)));
    }

    /* ERC4626 (INTERNAL) */

    /// @inheritdoc ERC4626
    function _decimalsOffset() internal view override returns (uint8) {
        return DECIMALS_OFFSET;
    }

    /// @dev Returns the maximum amount of asset (`assets`) that the `owner` can withdraw from the vault, as well as the
    /// new vault's total supply (`newTotalSupply`) and total assets (`newTotalAssets`).
    function _maxWithdraw(address owner)
        internal
        view
        returns (uint256 assets, uint256 newTotalSupply, uint256 newTotalAssets)
    {
        uint256 feeShares;
        (feeShares, newTotalAssets) = _accruedFeeShares();
        newTotalSupply = totalSupply() + feeShares;

        assets = _convertToAssetsWithTotals(balanceOf(owner), newTotalSupply, newTotalAssets, Math.Rounding.Floor);

        // can never withdraw more than the underlying vault can withdraw
        assets = Utils.min(assets, VAULT.maxWithdraw(address(this)));
    }

    /// @dev Returns the maximum amount of assets that the vault can supply on the underlying vault.
    function _maxDeposit() internal view returns (uint256 totalSuppliable) {
        return VAULT.maxDeposit(address(this));
    }

    /// @inheritdoc ERC4626
    /// @dev The accrual of performance fees is taken into account in the conversion.
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256) {
        (uint256 feeShares, uint256 newTotalAssets) = _accruedFeeShares();
        return _convertToSharesWithTotals(assets, totalSupply() + feeShares, newTotalAssets, rounding);
    }

    /// @inheritdoc ERC4626
    /// @dev The accrual of performance fees is taken into account in the conversion.
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256) {
        (uint256 feeShares, uint256 newTotalAssets) = _accruedFeeShares();
        return _convertToAssetsWithTotals(shares, totalSupply() + feeShares, newTotalAssets, rounding);
    }

    /// @dev Returns the amount of shares that the vault would exchange for the amount of `assets` provided.
    /// @dev It assumes that the arguments `newTotalSupply` and `newTotalAssets` are up to date.
    function _convertToSharesWithTotals(
        uint256 assets,
        uint256 newTotalSupply,
        uint256 newTotalAssets,
        Math.Rounding rounding
    ) internal view returns (uint256) {
        return assets.mulDiv(newTotalSupply + 10 ** _decimalsOffset(), newTotalAssets + 1, rounding);
    }

    /// @dev Returns the amount of assets that the vault would exchange for the amount of `shares` provided.
    /// @dev It assumes that the arguments `newTotalSupply` and `newTotalAssets` are up to date.
    function _convertToAssetsWithTotals(
        uint256 shares,
        uint256 newTotalSupply,
        uint256 newTotalAssets,
        Math.Rounding rounding
    ) internal view returns (uint256) {
        return shares.mulDiv(newTotalAssets + 1, newTotalSupply + 10 ** _decimalsOffset(), rounding);
    }

    /// @inheritdoc ERC4626
    /// @dev Used in mint or deposit to deposit the underlying asset
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        VAULT.deposit(assets, address(this));

        // `lastTotalAssets + assets` may be a little off from `totalAssets()`.
        _updateLastTotalAssets(lastTotalAssets + assets);
    }

    /// @inheritdoc ERC4626
    /// @dev Used in redeem or withdraw to withdraw the underlying asset from the underlying vault.
    /// @dev Depending on 3 cases, reverts when withdrawing "too much" with:
    /// 1. NotEnoughLiquidity when withdrawing more than available liquidity.
    /// 2. ERC20InsufficientAllowance when withdrawing more than `caller`'s allowance.
    /// 3. ERC20InsufficientBalance when withdrawing more than `owner`'s balance.
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        VAULT.withdraw(assets, address(this), address(this));

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /* FEE MANAGEMENT */

    /// @dev Updates `lastTotalAssets` to `updatedTotalAssets`.
    function _updateLastTotalAssets(uint256 updatedTotalAssets) internal {
        lastTotalAssets = updatedTotalAssets;

        emit Events.UpdateLastTotalAssets(updatedTotalAssets);
    }

    /// @dev Accrues the fee and mints the fee shares to the fee recipient.
    /// @return newTotalAssets The vaults total assets after accruing the interest.
    function _accrueFee() internal returns (uint256 newTotalAssets) {
        uint256 feeShares;
        (feeShares, newTotalAssets) = _accruedFeeShares();

        if (feeShares != 0) _mint(feeRecipient, feeShares);

        emit Events.AccrueInterest(newTotalAssets, feeShares);
    }

    /// @dev Computes and returns the fee shares (`feeShares`) to mint and the new vault's total assets
    /// (`newTotalAssets`).
    function _accruedFeeShares() internal view returns (uint256 feeShares, uint256 newTotalAssets) {
        newTotalAssets = totalAssets();

        uint256 totalInterest = newTotalAssets.zeroFloorSub(lastTotalAssets);
        if (totalInterest != 0 && fee != 0) {
            // It is acknowledged that `feeAssets` may be rounded down to 0 if `totalInterest * fee < WAD`.
            uint256 feeAssets = totalInterest.mulDiv(fee, WAD);
            // The fee assets is subtracted from the total assets in this calculation to compensate for the fact
            // that total assets is already increased by the total interest (including the fee assets).
            feeShares =
                _convertToSharesWithTotals(feeAssets, totalSupply(), newTotalAssets - feeAssets, Math.Rounding.Floor);
        }
    }
}
