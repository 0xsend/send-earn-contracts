pragma solidity 0.8.19;

import "morpho-blue/Morpho.sol";

/// @dev Convinces the compiler to compile Morpho.sol to the artifacts directory.
contract MockMorpho is Morpho {
    constructor(address owner) Morpho(owner) {}
}
