//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/// @title  Governance
/// @notice Governance to govern the registry
contract Governance {
    using BitMaps for BitMaps.BitMap;
    /*///////////////////////////////////////////////////////////////
                      STATE
    //////////////////////////////////////////////////////////////*/

    // (erc20 address, attribute) => yesVotes
    mapping(address => mapping(uint256 => uint256)) public presentStatus;

    // (citizen, erc20Address) => atttibuteSet
    mapping(address => mapping(address => BitMaps.BitMap))
        internal citizenVotes;
    struct Vote {
        address erc20;
        uint256 attribute;
        bool support;
    }

    enum DegreeOfConfidence {
        complete,
        high,
        mid,
        low
    }
    mapping(uint256 => DegreeOfConfidence) getDegreeOfConfidence;

    uint256 public totalCitizens;
    mapping(address => bool) public citizen;

    /*///////////////////////////////////////////////////////////////
                      Events
    //////////////////////////////////////////////////////////////*/

    event NewERC20RegistrationRequest(
        address indexed logger,
        address erc20,
        uint256 number
    );

    event NewVote(address indexed erc20, uint256 attribute, bool support);

    /*///////////////////////////////////////////////////////////////
                      Setup
    //////////////////////////////////////////////////////////////*/

    constructor(address firstCitizen) {
        citizen[firstCitizen] = true;
        totalCitizens++;
        getDegreeOfConfidence[25] = DegreeOfConfidence.low;
        getDegreeOfConfidence[50] = DegreeOfConfidence.mid;
        getDegreeOfConfidence[80] = DegreeOfConfidence.high;
        getDegreeOfConfidence[100] = DegreeOfConfidence.complete;
    }

    modifier isCitizen() {
        require(citizen[msg.sender] == true, "Not a citizen");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                      VOTING ON ERC20 
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows anyone to request registration or reaudit for any new ERC20
    /// @dev Follwoing function will emit a event, which citizens index as a new request and do a audit
    /// @param _erc20 erc20 token address
    function requestAuditOfNewERC20(address _erc20) external {
        emit NewERC20RegistrationRequest(msg.sender, _erc20, block.timestamp);
        // @dev : we can discuss some locking of funds to avoid spam, but as we are indexing on basis of msg.sender, should be easy for auditors to filter
    }

    /// @notice Allows citizens to cast or update their votes
    /// @dev Votes can be updated for multiple erc20s, for multiple attribites at once
    /// @param newVotes newVotes in form of Vote struct
    function updateVote(Vote[] memory newVotes) external isCitizen {
        uint256 newVotesLength = newVotes.length;

        for (uint256 i = 0; i < newVotesLength; ++i) {
            BitMaps.BitMap storage prevVote = citizenVotes[msg.sender][
                newVotes[i].erc20
            ];

            // Only change state if new vote is different from prev vote
            if (prevVote.get(newVotes[i].attribute) != newVotes[i].support) {
                if (newVotes[i].support) {
                    presentStatus[newVotes[i].erc20][newVotes[i].attribute]++;
                } else {
                    presentStatus[newVotes[i].erc20][newVotes[i].attribute]--;
                }

                emit NewVote(
                    newVotes[i].erc20,
                    newVotes[i].attribute,
                    newVotes[i].support
                );

                prevVote.setTo(newVotes[i].attribute, newVotes[i].support);
            }
        }
    }

    /// @notice Allows anyone to query and check : With how much degree of confidence citizens believe that given erc20 has that attribute.
    /// @dev The higher is better if you are checking for positive, lower is better for negative
    /// @param _erc20 erc20 token address
    /// @param _attribute attribute index
    /// @return DegreeOfConfidence the degree of confidence in assertion that given erc20 has passed attribute
    function hasAttribute(address _erc20, uint256 _attribute)
        public
        view
        returns (DegreeOfConfidence)
    {
        return
            getDegreeOfConfidence[
                (presentStatus[_erc20][_attribute] * 100) / totalCitizens
            ];
    }

    /*///////////////////////////////////////////////////////////////
                      VOTING ON CITIZENSHIP
    //////////////////////////////////////////////////////////////*/
}
