// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {Platform} from "../../src/Platform.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract PlatformMock is Platform {
    constructor(address initialPlatform, address initialOwner) Platform(initialPlatform) Ownable(initialOwner) {}
    // solhint-disable-next-line no-empty-blocks
    function platformFunction() external onlyPlatform {}
    // solhint-disable-next-line no-empty-blocks
    function ownerFunction() external onlyOwner {}
}
