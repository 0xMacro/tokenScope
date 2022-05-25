pragma solidity ^0.8.0;

interface IRegistryClient {
    function tokenIsRegistered(address _token) external view returns (bool);

    function tokenIsValidERC20(address _token) external view returns (bool);

    function factsAreValidated(address _token, uint8[] calldata _facts)
        external
        view
        returns (bool);

    function factSetIsValidated(address _token, uint256 _factSet)
        external
        view
        returns (bool);

    function factsToFactSet(uint8[] calldata _facts)
        external
        pure
        returns (uint256 factSet);

    function factSetToFacts(uint256 _factSet)
        external
        pure
        returns (uint8[] memory);
}
