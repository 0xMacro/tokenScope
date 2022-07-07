//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IERC20RegistryClient.sol";
import "./MockPair.sol";

contract MockFactory {
    address public immutable registry;
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeToSetter, address _registry) {
        feeToSetter = _feeToSetter;
        registry = _registry;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS"); // single check is sufficient

        //---------------------------TokenScope----------------------------------//
        require(
            IERC20RegistryClient(registry).tokenIsValidERC20(tokenA) == OptionalBool.TRUE,
            "tokenA not ERC20"
        );
        require(
            IERC20RegistryClient(registry).tokenIsValidERC20(tokenB) == OptionalBool.TRUE,
            "tokenB not ERC20"
        );
        //---------------------------TokenScope----------------------------------//

        bytes memory bytecode = type(MockPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		// solhint-disable-next-line no-inline-assembly
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        MockPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
