//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Registry.sol";

/// @title  ClientTokenScope
/// @notice Mock contract to showcase TokenScope features

contract ClientTokenScope{
    Registry private immutable registiry;

    constructor(address _registiry) {
        registiry = Registry(_registiry);
    }
    
    /// @notice Checks if a token is in registiry
    /// @param token token address
    /// @return bool value whether the token is in registiry
    function isRegistered(address token) public view returns (bool){
        return registiry.tokenIsRegistered(token);
    }

    /// @notice Checks if a token is a valid registired ERC20
    /// @param token token address
    /// @return bool value whether the token is a valid ERC20
    function isValidERC20(address token) public view returns (bool){
        return registiry.tokenIsValidERC20(token);
    }

    /// @notice Checks if a token is both mintable and burnable
    ///         Uses "factsAreValidated" function of TokenScope to query multiple attributes from registery using an array of integers
    /// @param token token address
    /// @return bool value whether the token is both mintable and burnable
    function mintableAndBurnable(address token) public view returns(bool){
        // 4th attrivbute in the registiry => CAN_MINT
        // 5th attrivbute in the registiry => CAN_BURN 
        return registiry.factsAreValidated(token, [4, 5]);
    }

    /// @notice Checks if a token is a valid ERC20 that can be pausable
    ///         Uses "factSetIsValidated" function of TokenScope to query multiple attributes from registery using an integer corresponding to binary represantation of bits
    /// @param token token address
    /// @return bool value whether the token contract is a pausable valid ERC20 contract
    function isPausableValidERC20(address token) public view returns(bool){
        // 1 << 1 = 10 = 2th attribute in the registiry => IS_VALID_ERC20
        // 1 << 6 = 1000000 = 64 = 6th attribute in the registiry => IS_PAUSABLE
        // 1 << 1 | 1 << 6 = 1000010 = 66
        return registiry.factSetIsValidated(token,  1 << 1 | 1 << 6);
    } 

}
