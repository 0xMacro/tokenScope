//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/OptionalBitMaps.sol";

/// @title ERC20Registry
/// @author Paul Czajka [paul.czajka@gmail.com]
/// @notice Tokenscope ERC20 token registry
contract ERC20Registry is Ownable {
    // This contract registers facts for different ERC20 addresses.
	// A fact is an OptionalBool value, with possible values of `UNSET', 'TRUE', 'FALSE'.
	// The default value is 'UNSET', meaning the fact has either not been evaluated,
	// or is not definitively 'TRUE' or 'FALSE'.
	// Facts are registered to ERC20 token addresses: altering registry facts is accomplished
	// through governance.
    //
    // Each fact has to components:
	// - Fact ID: a unique uint256 value per fact (e.g. 0, 1, ...)
	// - Fact Code: a human-readable codes (e.g. "IS_VALID_ERC20")
    //
	// Fact IDs are automatically created in sequential order.
	// Fact Codes are not stored on chain: they are emitted in events
	// with their associated fact id upon creation.
    //
    // This contract is only aware of the current highwater fact id,
    // which defines the list of valid fact ids as 0 through highwater inclusive.
	//
	// This contract is not intended to be used with upgradeable ERC20 tokens.

    using OptionalBitMaps for OptionalBitMaps.OptionalBitMap;

    // Standard facts
    uint256 public constant IS_REGISTERED = 0; // Token exists in this contract. Set when added to registry
    uint256 public constant IS_VALID_ERC20 = 1; // Token conforms to ERC20 standard. Set by governance

    /// High-water mark for the highest fact id
    uint256 public highwaterFactId = 1;

    /// Maps an ERC20 token address to its set of validated facts
    mapping(address => OptionalBitMaps.OptionalBitMap) private tokenFacts;

    /// Emitted when a new fact is created.
    /// @param factId The fact identifer
    /// @param code The short descriptive code for this fact
    event ERC20FactCreated(uint256 factId, string code);

    /// Emitted when a token's set of validated facts is added/updated
    /// @param token The token
	/// @param tokenAdded Boolean flag if this token was newly added to the registry.  False means a token's existing registration was updated.
    /// @param factIds The factIds that were validated
    /// @param values The values corresponding to each factId
    event ERC20TokenAddUpdate(address indexed token, bool tokenAdded, uint256[] factIds, OptionalBool[] values);

    error TokenNotRegistered();
    error MaxFactsReached();
    error InvalidFact(uint256 factId, uint256 highwaterFactId);
	error InvalidArity();

    /// @param _governor The owning Governance contract
    constructor(address _governor) {
        // Governance contract is owner
        transferOwnership(_governor);

        // factCreated events are the effective "catalog" of facts available.
        // Emit the first to common facts so they show up in the catalog like all the rest.
        emit ERC20FactCreated(IS_REGISTERED, "IS_REGISTERED");
        emit ERC20FactCreated(IS_VALID_ERC20, "IS_VALID_ERC20");
    }


    /*/////////////////////////////////////////////////////////////////////////////////
        Registry Administration
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Create a new fact available for all tokens.
    /// Existing tokens will have an `UNSET` value for this fact, which can be updated by governance
    /// @param factCode The human-readable code for the fact being created. Emitted as an event, purely for reference.
    /// @dev The fact ID will be the next available ID, according to present `highwaterFactId`
    function createFact(string calldata factCode) external onlyOwner {
        emit ERC20FactCreated(++highwaterFactId, factCode);
    }

    /// Add or update an ERC20 token's set of validated facts.
    /// @param _token The token
    /// @param _factIds The factIds to be set
    /// @param _values The OptionalBool values corresponding to the _factIds
    /// @dev _values will overwrite the existing _factIds for this _token.
    function addUpdateERC20(address _token, uint256[] calldata _factIds, OptionalBool[] calldata _values)
        external
        onlyOwner
    {
		if (_factIds.length != _values.length) revert InvalidArity();

        OptionalBitMaps.OptionalBitMap storage _tokenFacts = tokenFacts[_token];


		// Mark as registered if this is a new token
		bool tokenAdded = _tokenFacts.get(IS_REGISTERED) != OptionalBool.TRUE;
		if (tokenAdded) {
			_tokenFacts.setTrue(IS_REGISTERED);
		}

        for( uint256 i = 0; i < _factIds.length; ++i) {
			// If there is an invalid factId present, we cautiously revert the entire transaction
            if(_factIds[i] > highwaterFactId) revert InvalidFact(_factIds[i], highwaterFactId);
            _tokenFacts.setTo(_factIds[i], _values[i]);
        }

        emit ERC20TokenAddUpdate(_token, tokenAdded, _factIds, _values);
    }


    /*/////////////////////////////////////////////////////////////////////////////////
        Registry Querying
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Convenience method to determine if a particular token exists in this registry
    /// @param _token The token
    /// @return bool
    function tokenIsRegistered(address _token) public view returns (bool) {
        return tokenFacts[_token].get(IS_REGISTERED) == OptionalBool.TRUE;
    }

    /// Convenience method to determine if a particular token is a valid ERC20 implementation
    /// @param _token The token
    /// @return bool
    function tokenIsValidERC20(address _token)
        external
        view
        returns (OptionalBool)
    {
        return tokenFacts[_token].get(IS_VALID_ERC20);
    }

    /// Query a series of facts for a single token. Returns an array of OptionalBool values
	/// which correspond to the supplied _factIds.
    /// @param _token The token
    /// @param _factIds The array of fact ids to be validated
    /// @return OptionalBool[]
    function queryTokenFacts(address _token, uint256[] calldata _factIds)
        external
        view
        returns (OptionalBool[] memory)
    {
        OptionalBool[] memory results = new OptionalBool[](_factIds.length);
        OptionalBitMaps.OptionalBitMap storage _tokenFacts = tokenFacts[_token];

        // We can skip looking up facts if the token is not registered.
        // In this case all facts will be the default value of OptionalBool.UNSET
        if (_tokenFacts.get(IS_REGISTERED) == OptionalBool.TRUE) {
            for(uint256 i = 0; i < _factIds.length; ++i) {
                results[i] = _tokenFacts.get(_factIds[i]);
            }
        }

        return results;
    }
}
