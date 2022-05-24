//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ERC20Registry
/// @author Paul Czajka [paul.czajka@gmail.com]
/// @notice Tokenscope ERC20 token registry
contract ERC20Registry is Ownable {

    // This contract stores up to 256 unique facts for each token.
    // A fact has two parts:
    //   id: a uint8 value, 0 - 255
    //   code: a string description of the fact
    //
    // Fact codes are not stored on-chain: they are emitted as events
    // upon creation. Fact ids are assigned in sequential order, and
    // this contract is only aware of the current highwater fact id,
    // which defines the list of valid fact ids as 0 through highwater inclusive.
    //
    // Each fact code needs to be formulated such that a fact value of '1'
    // means the fact has been validated by governance.  A fact value
    // of '0' means the fact has not been validated, so it can be either not true
    // or not yet validated. Client contract authors special take note of this.
    //
    // Each uint8 fact id correlates to the bit-position of a uint256,
    // so the entire 256 fact-space for a single token can be condensed
    // into a single uint256. This flattened representation of the entire
    // fact space is termed a 'factSet'.
    //
    // Client contracts can query a set of facts for a token in one of two ways:
    // - areFactsValidated() accepts an array of uint8 fact ids
    // - isFactSetValidated() accepts a flattened uint256 factSet
    // These methods return true IFF all represented facts have been validated.
    //
    // Note that isFactSetValidated() will not produce correct results if supplied
    // with a uint256-casted fact id.  Use factsToFactSet() to convert individual
    // fact ids to a correct factSet representation.


    // Standard facts
    uint8 public constant IS_REGISTERED = 0;  // Token exists in this contract. Set to 1 when added to registry
    uint8 public constant IS_VALID_ERC20 = 1; // Token conforms to ERC20 standard. Set by governance

    /// High-water mark for the highest fact id (factSet bit-position)
    uint8 public highwaterFact = 1;

    /// Maps a token address to its set of validated facts
    mapping(address => uint256) public tokenFacts;

    /// Emitted when a new fact is created.
    /// @param fact The unique fact identifer: also the identifier of the fact in token factSets.
    /// @param code The short descriptive code for this fact.
    event ERC20FactCreated(uint8 fact, string code);

    /// Emitted when a token's set of validated facts is added/updated
    /// @param token The token
    /// @param validatedFacts The new validated fact set of the token
    event ERC20ValidatedFacts(address indexed token, uint256 validatedFacts);


    /// @param _governor The owning Governance contract
    constructor(address _governor) {
        // Governance contract is owner
        transferOwnership(_governor); 

        // factCreated events are the effective "catalog" of facts available.
        // Emit the first to common facts so they show up in the catalog like all the rest.
        emit ERC20FactCreated(IS_REGISTERED, "IS_REGISTERED");
        emit ERC20FactCreated(IS_VALID_ERC20, "IS_VALID_ERC20");
    }

    /// The token must be registered
    /// @param _token The token
    modifier isRegistered(address _token) {
        require(tokenFacts[_token] & IS_REGISTERED == IS_REGISTERED, "TOKEN_NOT_REGISTERED");
        _;
    }

    /// The fact set must only represent facts that have been defined (bit position <= high water mark)
    /// @param _factSet The fact set
    modifier validFactSet(uint256 _factSet) {
        if (highwaterFact < 255) {
            // The highest valid factSet value would have all bits set to 1 for all created facts.
            // "1 << (highwaterFact + 1)" creates a factSet that exceeds this number by 1:
            // subtracting one yields the value where all bits are set to 1 for all created facts.
            require(_factSet <= (1 << (highwaterFact + 1)) - 1, "INVALID_FACT_SET");
        }
        _;
    }

    function _isValidated(address _token, uint256 _factSet) private view returns (bool) {
        // An individual fact is validated if its bit-position is set to 1.
        // We can validate multiple facts at once.
        return tokenFacts[_token] & _factSet == _factSet;
    }


    /*/////////////////////////////////////////////////////////////////////////////////
        Registry Administration
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Create a new fact available for all tokens.
    /// Existing tokens will have a `false` value for this fact, which can be updated by governance actions
    /// @param factCode The code for the fact being created
    /// @dev The fact identifer will be the next available bit-position, according to present `highwaterFact`
    function createFact(string calldata factCode) external onlyOwner {
        require(highwaterFact < 255, "MAX_FACTS_REACHED");

        emit ERC20FactCreated(++highwaterFact, factCode);
    }

    /// Add or update an ERC20 token with its set of validated facts.
    /// @param _token The token
    /// @param _factSet The set of all validated facts for the token
    /// @dev If the token already exists, its present factSet will be entirely overwritten by this new value.
    function addUpdateERC20(address _token, uint256 _factSet) external onlyOwner validFactSet(_factSet) {
        // The IS_REGISTERED attr is always true in storage
        //  (1 << IS_REGISTERED) = 1
        tokenFacts[_token] = _factSet | 1;

        emit ERC20ValidatedFacts(_token, _factSet | 1);
    }


    /*/////////////////////////////////////////////////////////////////////////////////
        Registry Querying
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Convenience method to determine if a particular token exists in this registry
    /// @param _token The token
    /// @return bool
    function tokenIsRegistered(address _token) external view returns (bool) {
        // Second argument: 1 << IS_REGISTERED = 1
        return _isValidated(_token, 1);
    }

    /// Convenience method to determine if a particular token is a valid ERC20 implementation
    /// @param _token The token
    /// @return bool
    function tokenIsValidERC20(address _token) external view isRegistered(_token) returns (bool) {
        // Second argument: 1 << IS_VALID_ERC20 = 2
        return _isValidated(_token, 2);
    }

    /// Return whether specific facts have all been validated for a token.
    /// @param _token The token
    /// @param _facts The array of uint8 fact ids to be validated
    /// @return bool
    function factsAreValidated(address _token, uint8[] calldata _facts) external view isRegistered(_token) returns (bool) {
        return factSetIsValidated(_token, factsToFactSet(_facts));
    }

    /// Return whether a token conforms to a set of facts.
    /// This method returns true if the token conforms to all flagged facts:
    /// any facts above and beyond the flagged ones are not accounted for and wil have no impact on the result.
    /// @param _token The token
    /// @param _factSet The flattened uint256 fact set to be validated
    function factSetIsValidated(address _token, uint256 _factSet) public view isRegistered(_token) validFactSet(_factSet) returns (bool) {
        return _isValidated(_token, _factSet);
    }

    /*/////////////////////////////////////////////////////////////////////////////////
        Utility Conversion Methods
    /////////////////////////////////////////////////////////////////////////////////*/

    /// Convert an array of fact values into a single factSet value
    /// @dev Does not validate that any particular fact values exist
    /// @param _facts The array of fact values to convert into a fact set
    /// @return factSet
    function factsToFactSet(uint8[] calldata _facts) public pure returns (uint256 factSet) {
        uint len = _facts.length;
        for (uint i = 0 ; i < len; ++i) {
            factSet = factSet | (1 << _facts[i]);
        }
    }

    /// Convert an factSet value into an array of fact values
    /// @dev Does not validate that any particular fact values exist
    /// @param _factSet The fact set to convert into an array of fact values
    /// @return uint8[]
    function factSetToFacts(uint256 _factSet) external pure returns (uint8[] memory) {

        // We can't create a dynamic memory array, so we need to loop twice:
        // 1) Discover the number of facts. Then we size the facts array appropriately
        // 2) Populate the facts array
        uint8 n;
        uint256 factSetCopy = _factSet;

        // Determine the number of facts
        for (uint8 i = 0; i < 255; ++i) {
            if (factSetCopy & 1 == 1) {
                ++n;
            }
            factSetCopy = factSetCopy >> 1;
        }

        // Size the return array appropriately
        uint8[] memory facts = new uint8[](n);
        n = 0;
        factSetCopy = _factSet;

        // Populate the facts
        for (uint8 i = 0; i < 255; ++i) {
            if (factSetCopy & 1 == 1) {
                facts[n++] = i;
            }
            factSetCopy = factSetCopy >> 1;
        }

        return facts;
    }
}
