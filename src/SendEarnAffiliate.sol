// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Events} from "./lib/Events.sol";
import {Errors} from "./lib/Errors.sol";
import {Constants} from "./lib/Constants.sol";
import {ISendEarnAffiliate, ISplitConfig} from "./interfaces/ISendEarnAffiliate.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {UtilsLib} from "morpho-blue/libraries/UtilsLib.sol";

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
    IERC20 public immutable override token;

    /* CONSTRUCTOR */

    constructor(address _affiliate, address _splitConfig, address _token) {
        if (_token == address(0)) revert Errors.ZeroAddress();
        if (_affiliate == address(0)) revert Errors.ZeroAddress();
        if (_splitConfig == address(0)) revert Errors.ZeroAddress();
        affiliate = _affiliate;
        splitConfig = ISplitConfig(_splitConfig);
        token = IERC20(_token);
    }

    /// @inheritdoc ISendEarnAffiliate
    function pay() external {
        uint256 amount = token.balanceOf(address(this));
        if (amount == 0) revert Errors.ZeroAmount();

        uint256 split = splitConfig.split();
        uint256 platformSplit = amount.mulDiv(split, Constants.SPLIT_TOTAL);
        uint256 affiliateSplit = amount.mulDiv(Constants.SPLIT_TOTAL - split, Constants.SPLIT_TOTAL);

        token.safeTransfer(splitConfig.platform(), platformSplit);
        token.safeTransfer(affiliate, affiliateSplit);

        emit Events.AffiliatePay(msg.sender, amount, platformSplit, affiliateSplit);
    }
}
