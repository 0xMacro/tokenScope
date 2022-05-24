//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract Governance {

    using BitMaps for BitMaps.BitMap;

    /*///////////////////////////////////////////////////////////////
                      STATE
    //////////////////////////////////////////////////////////////*/

    // (erc20 address, attribute)=> yesVotes
    mapping(address => mapping(uint256 => uint256)) public presentStatus;

    // (citizen, erc20Address) => atttibuteSet)
    mapping(address => mapping(address => BitMaps.BitMap)) internal citizenVotes;
    struct Vote {
        address erc20;
        uint256 attribute;
        bool support;
    }
    
    enum DegreeOfConfidence{complete, majority, midway, low}
    mapping (uint256 => DegreeOfConfidence) getDegreeOfConfidence;

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

    event NewVote(
        address indexed erc20,
        uint256 attribute,
        bool support
    );

    /*///////////////////////////////////////////////////////////////
                      Setup
    //////////////////////////////////////////////////////////////*/

    constructor(address firstCitizen) {
        citizen[firstCitizen] = true;
        totalCitizens++;
        getDegreeOfConfidence[25] = DegreeOfConfidence.low;
        getDegreeOfConfidence[50] = DegreeOfConfidence.midway;
        getDegreeOfConfidence[80] = DegreeOfConfidence.majority;
        getDegreeOfConfidence[100] = DegreeOfConfidence.complete;
    }

    modifier isCitizen() {
        require(citizen[msg.sender] == true, "Not a citizen");
    }

    /*///////////////////////////////////////////////////////////////
                      VOTING ON ERC20 
    //////////////////////////////////////////////////////////////*/

    function requestAuditOfNewERC20(address _erc20) external {
        emit NewERC20RegistrationRequest(msg.sender, _erc20, block.timestamp);
    }

    function updateVote(Vote[] memory newVotes) external isCitizen {
        uint256 newVotesLength = newVotes.length;

        for (uint256 i = 0; i < newVotesLength; ++i) {
            BitMaps.BitMap storage prevVote = citizenVotes[msg.sender][
                newVotes[i].erc20
            ];

            if (prevVote.get(newVotes[i].attribute) != newVotes[i].support) {
                if (newVotes[i].support) {
                    presentStatus[newVotes[i].erc20][newVotes[i].attribute]++;
                } else {
                    presentStatus[newVotes[i].erc20][newVotes[i].attribute]--;
                }
                
                emit NewVote(newVotes[i].erc20, newVotes[i].attribute, newVotes[i].support);

                prevVote.setTo(newVotes[i].attribute, newVotes[i].support);
            }
        }
    }

    function hasAttribute(address _erc20, uint256 _attribute) public returns (DegreeOfConfidence)
    {   
        return getDegreeOfConfidence[(presentStatus[_erc20][_attribute] * 100)/ totalCitizens];
    }


    /*///////////////////////////////////////////////////////////////
                      VOTING ON CITIZENSHIP
    //////////////////////////////////////////////////////////////*/




}
