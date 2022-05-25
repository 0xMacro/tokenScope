//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../ERC20Registry.sol";

/// @title  ClientTokenScope
/// @notice Mock contract to showcase TokenScope features

contract ClientTokenScope {
    ERC20Registry private immutable registiry;

    constructor(address _registiry) {
        registiry = ERC20Registry(_registiry);
    }

    /// @notice Checks if a token is in registiry
    /// @param token token address
    /// @return bool value whether the token is in registiry
    function isRegistered(address token) public view returns (bool) {
        return registiry.tokenIsRegistered(token);
    }

    /// @notice Checks if a token is a valid ERC20
    /// @param token token address
    /// @return bool value whether the token is a valid ERC20
    function isValidERC20(address token) public view returns (bool) {
        return registiry.tokenIsValidERC20(token);
    }

    /// @notice Checks if a token is valid ERC20
    ///         Uses "factsAreValidated" function of TokenScope to query multiple facts from registery using an array of indexes
    /// @param token token address
    /// @return bool value whether the token is a valid ERC20
    function isValidERC20usingFactId(address token) public view returns (bool) {
        // id = 1 => 2th fact in the registiry => IS_VALID_ERC20
        uint8[] memory t = new uint8[](1);
        t[0] = 1;
        return registiry.factsAreValidated(token, t);
    }

    /// @notice Checks if a token is valid ERC20
    ///         Uses "factSetIsValidated" function of TokenScope to query multiple facts from registery using an integer corresponding to binary represantation of bits
    /// @param token token address
    /// @return bool value whether the token is a valid ERC20
    function isValidERC20usingFactSet(address token)
        public
        view
        returns (bool)
    {
        // 1 << 1 = 10 = 2th fact in the registiry => IS_VALID_ERC20
        return registiry.factSetIsValidated(token, 1 << 1);
    }
}
