// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ISplitConfig} from "./ISplitConfig.sol";

interface ISendEarnAffiliate {
    /// @notice The address of the affiliate split config.
    function splitConfig() external view returns (ISplitConfig);
    /// @notice The address of the affiliate receiving the earnings.
    function affiliate() external view returns (address);
    /// @notice The token to split
    function token() external view returns (IERC20);
    /// @notice Pays out the earnings to the platform and affiliate.
    function pay() external;
}
