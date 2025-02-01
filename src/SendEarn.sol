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
import {WAD} from "morpho-blue/libraries/MathLib.sol";
import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";

/// @title SendEarn
/// @author Send Squad
/// @notice ERC4626 vault allowing users to deposit USDC to earn yield through Morpho & Morpho
contract SendEarn is ERC4626, ERC20Permit, Ownable2Step {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /* IMMUTABLES */

    /// @notice The MetaMorpho vault contract
    IERC4626 public immutable META_MORPHO;

    /// @notice OpenZeppelin decimals offset used by the ERC4626 implementation
    uint8 public immutable DECIMALS_OFFSET;

    /* STORAGE */

    /// @notice the current fee
    uint96 public fee;

    /// @notice The fee recipient
    address public feeRecipient;

    /// @notice Referral fee basis points taken from the current fee
    uint96 public feeReferral;

    /// @notice Tracks referral relationships
    mapping(address user => address referrer) public referrers;

    /// @notice The last total assets
    uint256 public lastTotalAssets;

    // TODO: Add fee tracking/accounting variables

    /* EVENTS */

    // TODO: Add events

    /* ERRORS */

    // TODO: Add errors

    /* CONSTRUCTOR */

    constructor(
        address owner,
        address metaMorpho,
        address asset,
        string memory _name,
        string memory _symbol
    )
        ERC4626(IERC20(asset))
        ERC20Permit(_name)
        ERC20(_name, _symbol)
        Ownable(owner)
    {
        if (metaMorpho == address(0)) revert Errors.ZeroAddress();
        META_MORPHO = IERC4626(metaMorpho);
        DECIMALS_OFFSET = uint8(
            UtilsLib.zeroFloorSub(uint256(18), IERC20Metadata(asset).decimals())
        );

        // TODO: Initialize other state variables

        // Approve Morpho vault to spend our underlying asset
        IERC20(asset).approve(metaMorpho, type(uint256).max);
    }

    /* OWNER ONLY */

    function setFee(uint256 newFee) external onlyOwner {
        if (newFee == fee) revert Errors.AlreadySet();
        if (newFee > Constants.MAX_FEE) revert Errors.MaxFeeExceeded();
        if (newFee != 0 && feeRecipient == address(0))
            revert Errors.ZeroFeeRecipient();

        // Accrue fee using the previous fee set before changing it.
        _updateLastTotalAssets(_accrueFee());

        // Safe "unchecked" cast because newFee <= MAX_FEE.
        fee = uint96(newFee);

        emit Events.SetFee(_msgSender(), fee);
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        feeRecipient = newFeeRecipient;

        emit Events.SetFeeRecipient(newFeeRecipient);
    }

    function setFeeReferral(uint256 newFeeReferral) external onlyOwner {
        if (newFeeReferral == feeReferral) revert Errors.AlreadySet();
        // TODO: double check unchecked cast
        feeReferral = uint96(newFeeReferral);

        emit Events.SetFeeReferral(msg.sender, newFeeReferral);
    }

    /* REFERRER */

    /// @notice Sets the referrer of the sender
    function setReferrer(address referrer) external {
        referrers[msg.sender] = referrer;
        emit Events.SetReferrer(msg.sender, referrer);
    }

    /* ERC4626 (PUBLIC) */

    /// @inheritdoc IERC20Metadata
    function decimals() public view override(ERC20, ERC4626) returns (uint8) {
        return ERC4626.decimals();
    }

    /// @inheritdoc ERC4626
    function maxDeposit(
        address receiver
    ) public view override returns (uint256) {
        return META_MORPHO.maxDeposit(receiver);
    }

    function totalAssets() public view override returns (uint256) {
        return META_MORPHO.totalAssets();
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
        (uint256 feeShares, uint256 newTotalAssets) = _accruedFeeShares();
        return
            _convertToSharesWithTotals(
                assets,
                totalSupply() + feeShares,
                newTotalAssets,
                rounding
            );
    }

    /// @inheritdoc ERC4626
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view override returns (uint256) {
        (uint256 feeShares, uint256 newTotalAssets) = _accruedFeeShares();
        return
            _convertToAssetsWithTotals(
                shares,
                totalSupply() + feeShares,
                newTotalAssets,
                rounding
            );
    }

    function _convertToSharesWithTotals(
        uint256 assets,
        uint256 newTotalSupply,
        uint256 newTotalAssets,
        Math.Rounding rounding
    ) internal view returns (uint256) {
        return
            assets.mulDiv(
                newTotalSupply + 10 ** _decimalsOffset(),
                newTotalAssets + 1,
                rounding
            );
    }

    function _convertToAssetsWithTotals(
        uint256 shares,
        uint256 newTotalSupply,
        uint256 newTotalAssets,
        Math.Rounding rounding
    ) internal view returns (uint256) {
        return
            shares.mulDiv(
                newTotalAssets + 1,
                newTotalSupply + 10 ** _decimalsOffset(),
                rounding
            );
    }

    /* FEE MANAGEMENT */

    function _updateLastTotalAssets(uint256 updatedTotalAssets) internal {
        lastTotalAssets = updatedTotalAssets;

        emit Events.UpdateLastTotalAssets(updatedTotalAssets);
    }

    function _accrueFee() internal returns (uint256 newTotalAssets) {
        uint256 feeShares;
        (feeShares, newTotalAssets) = _accruedFeeShares();

        if (feeShares != 0) _mint(feeRecipient, feeShares);

        emit Events.AccrueInterest(newTotalAssets, feeShares);
    }

    function _accruedFeeShares()
        internal
        view
        returns (uint256 feeShares, uint256 newTotalAssets)
    {
        newTotalAssets = totalAssets();

        uint256 totalInterest = UtilsLib.zeroFloorSub(
            newTotalAssets,
            lastTotalAssets
        );
        if (totalInterest != 0 && fee != 0) {
            // It is acknowledged that `feeAssets` may be rounded down to 0 if `totalInterest * fee < WAD`.
            uint256 feeAssets = totalInterest.mulDiv(fee, WAD);
            // The fee assets is subtracted from the total assets in this calculation to compensate for the fact
            // that total assets is already increased by the total interest (including the fee assets).
            feeShares = _convertToSharesWithTotals(
                feeAssets,
                totalSupply(),
                newTotalAssets - feeAssets,
                Math.Rounding.Floor
            );
        }
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
        META_MORPHO.deposit(assets, address(this));
        // 3. Calculate and track fees
        _updateLastTotalAssets(lastTotalAssets + assets);
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
