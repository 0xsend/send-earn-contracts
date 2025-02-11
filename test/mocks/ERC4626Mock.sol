// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {ERC4626, IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

contract ERC4626Mock is ERC4626 {
    constructor(IERC20 _asset, string memory _name, string memory _symbol) ERC4626(_asset) ERC20(_name, _symbol) {}
}
