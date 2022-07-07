//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {OptionalBool} from "../libraries/OptionalBitMaps.sol";

interface IERC20RegistryClient {
    function tokenIsRegistered(address _token) external view returns (bool);

    function tokenIsValidERC20(address _token)
        external
        view
        returns (OptionalBool);

    function queryTokenFacts(address _token, uint256[] calldata _factIds)
        external
        view
        returns (OptionalBool[] memory);
}
