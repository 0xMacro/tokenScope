//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Governor {
    // constants
    uint256 public constant VOTING_PERIOD = 30 days;
    // variables
    mapping(address => bool) public members;
    uint256 public totalMembers;

    struct Receipt {
        bool hasVoted;
        bool support;
    }

    struct Proposal {
        // slot 1
        uint128 start;
        uint128 end;
        // slot 2
        address proposer;
        bool executed;
        // slot 3
        uint128 forVotes;
        uint128 againstVotes;
        mapping(address => Receipt) receipts;
    }

    mapping(uint256 => Proposal) public proposals;

    enum ProposalState {
        Executed,
        Active,
        Succeeded,
        Defeated
    }

    /*///////////////////////////////////////////////////////////////
                      MEMEBERSHIP
    //////////////////////////////////////////////////////////////*/

    // events
    event newMember(address add);

    // errrors
    error NotAllowed();
    error AlreadyMember();
    error NotAMember();

    constructor(address firstCitizen) {
        totalMembers++;
        members[firstCitizen] = true;
        emit newMember(firstCitizen);
    }

    function addMember(address _newMember) external {
        if (msg.sender != address(this)) revert NotAllowed();
        if (members[_newMember] != false) revert AlreadyMember();
        totalMembers++;
        members[_newMember] = true;
        emit newMember(_newMember);
    }

    function isMember(address _add) internal view {
        if (!members[_add]) revert NotAMember();
    }

    /*///////////////////////////////////////////////////////////////
                      PROPOSAL
    //////////////////////////////////////////////////////////////*/

    // events
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock
    );
    event ProposalExecuted(uint256 proposalId);

    // errors
    error InvalidProposal(string reason);
    error RevertForCall(uint256 proposalId, uint256 position);
    error NotAProposer();
    error NotSucceededOrAlreadyExecuted();
    error ProposalAlreadyExecuted();

    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[proposalId];

        if (p.executed) return ProposalState.Executed;
        if (p.start == 0) revert InvalidProposal("NotDefined");
        if (p.end >= block.timestamp) return ProposalState.Active;
        if (_isSucceeded(p)) return ProposalState.Succeeded;
        return ProposalState.Defeated;
    }

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas)));
    }

    function isValidProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) public pure returns (uint256 id) {
        if (targets.length != values.length)
            revert InvalidProposal("targets!=values");
        if (targets.length != calldatas.length)
            revert InvalidProposal("targets!=calldatas");
        if (targets.length == 0) revert InvalidProposal("empty");

        id = hashProposal(targets, values, calldatas);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external returns (uint256) {
        uint256 proposalId = isValidProposal(targets, values, calldatas);
        uint256 _start = block.timestamp;
        uint256 _end = _start + VOTING_PERIOD;
        proposals[proposalId].start = uint128(_start);
        proposals[proposalId].end = uint128(_end);
        proposals[proposalId].proposer = msg.sender;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            calldatas,
            _start,
            _end
        );
        return proposalId;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external {
        uint256 proposalId = hashProposal(targets, values, calldatas);
        // Check
        if (state(proposalId) != ProposalState.Succeeded)
            revert NotSucceededOrAlreadyExecuted();

        // Effect
        proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);

        // Interaction
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{
                value: values[i]
            }(calldatas[i]);
            if (!success) {
                if (returndata.length == 0) revert RevertForCall(proposalId, i);
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                          VOTE
    //////////////////////////////////////////////////////////////*/

    // events
    event VoteCast(address indexed voter, uint256 proposalId, bool support);

    // errors
    error VotingClosed();
    error AlreadyVoted();

    function castVote(uint256 proposalId, bool support) external {
        return _castVote(msg.sender, proposalId, support);
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal {
        isMember(voter);
        if (state(proposalId) != ProposalState.Active) revert VotingClosed();

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];

        if (receipt.hasVoted) revert AlreadyVoted();

        if (support) proposal.forVotes++;
        else proposal.againstVotes++;

        receipt.hasVoted = true;
        receipt.support = support;

        emit VoteCast(voter, proposalId, support);
    }

    function _isSucceeded(Proposal storage proposal)
        internal
        view
        returns (bool)
    {
        if (proposal.forVotes >= (totalMembers * 90) / 100) return true;
        else return false;
    }
}
