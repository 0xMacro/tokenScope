import { expect } from "chai";
import { ethers } from "hardhat";
import { utils, BigNumber } from "ethers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import type { Governor, ERC20Registry } from "../typechain/";

describe("Governor ", function () {
  let governor: Governor;
  let registry: ERC20Registry;
  let citizen1: SignerWithAddress;
  let citizen2: SignerWithAddress;
  let citizen3: SignerWithAddress;
  let citizen4: SignerWithAddress;
  let citizen5: SignerWithAddress;

  const ERC20_1 = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const ERC20_2 = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984";
  before(async function () {
    [citizen1, citizen2, citizen3, citizen4, citizen5] =
      await ethers.getSigners();
    const Governor = await ethers.getContractFactory("Governor");
    governor = <Governor>(
      await Governor.deploy(75, [
        citizen1.address,
        citizen2.address,
        citizen3.address,
        citizen4.address,
      ])
    );
    await governor.deployed();

    const registryFactory = await ethers.getContractFactory("ERC20Registry");
    registry = <ERC20Registry>await registryFactory.deploy(governor.address);
    await registry.deployed();
  });

  it("Setup Check ", async function () {
    expect(await governor.members(citizen1.address)).to.eq(true);
    expect(await governor.members(citizen5.address)).to.eq(false);
    expect(await governor.totalMembers()).to.eq(4);
  });

  it("Add Member ", async function () {
    /* ///////////////////////////////////////////////////////////////
                      ADD CITIZEN 4
    ////////////////////////////////////////////////////////////// */

    const calldata =
      "0xca6d56dc" + "000000000000000000000000" + citizen5.address.slice(2);

    // Proposal
    const proposalId = await governor.hashProposal(
      [governor.address],
      [0],
      [calldata],
      "addCitzen4"
    );
    expect(governor.state(proposalId)).revertedWith(
      'InvalidProposal("NotDefined")'
    );
    await governor.propose([governor.address], [0], [calldata], "addCitzen4");
    expect(
      governor.propose([governor.address], [0], [calldata], "addCitzen4")
    ).revertedWith('InvalidProposal("Duplicate")');
    expect(await governor.state(proposalId)).to.eq(1);
    const proposal = await governor.proposals(proposalId);
    expect(proposal.end).to.eq(proposal.start.add(30 * 60 * 60 * 24));

    // Vote
    expect(governor.connect(citizen5).castVote(proposalId, true)).revertedWith(
      "NotAMember()"
    );

    await governor.castVote(proposalId, true);
    expect(governor.castVote(proposalId, true)).revertedWith("AlreadyVoted()");
    expect(governor.castVote(proposalId, false)).revertedWith("AlreadyVoted()");
    await governor.connect(citizen2).castVote(proposalId, true);
    await governor.connect(citizen3).castVote(proposalId, true);

    expect(await governor.state(proposalId)).to.eq(2);

    // Execute
    await governor.execute([governor.address], [0], [calldata], "addCitzen4");
    expect(await governor.members(citizen5.address)).to.eq(true);
    expect(await governor.totalMembers()).to.eq(5);
    expect(
      governor.execute([governor.address], [0], [calldata], "addCitzen4")
    ).revertedWith("NotSucceededOrAlreadyExecuted()");
    expect(governor.connect(citizen5).castVote(proposalId, true)).revertedWith(
      "VotingClosed()"
    );
  });

  it("Remove Member ", async function () {
    /* ///////////////////////////////////////////////////////////////
                      REMOVE CITIZEN 5
    ////////////////////////////////////////////////////////////// */
    expect(governor.removeMember(citizen5.address)).revertedWith(
      "NotAllowed()"
    );
    const calldata =
      "0x0b1ca49a" + "000000000000000000000000" + citizen5.address.slice(2);
    expect(await governor.members(citizen5.address)).to.eq(true);
    const proposalId = await governor.hashProposal(
      [governor.address],
      [0],
      [calldata],
      "removeCitzen5"
    );
    await governor.propose(
      [governor.address],
      [0],
      [calldata],
      "removeCitzen5"
    );
    await governor.castVote(proposalId, true);
    await governor.connect(citizen2).castVote(proposalId, true);
    await governor.connect(citizen3).castVote(proposalId, true);
    await governor.connect(citizen5).castVote(proposalId, false);
    await governor.connect(citizen4).castVote(proposalId, true);
    await governor.execute(
      [governor.address],
      [0],
      [calldata],
      "removeCitzen5"
    );
    expect(await governor.members(citizen5.address)).to.eq(false);
    expect(await governor.totalMembers()).to.eq(4);
  });

  it("Change Quorum ", async function () {
    expect(governor.changeQuorum(80)).revertedWith("NotAllowed()");
    const calldata =
      "0xa12802cf" +
      "0000000000000000000000000000000000000000000000000000000000000032";
    expect(await governor.quorum()).to.eq(75);
    const proposalId = await governor.hashProposal(
      [governor.address],
      [0],
      [calldata],
      "changeQ50"
    );
    await governor.propose([governor.address], [0], [calldata], "changeQ50");
    await governor.castVote(proposalId, true);
    await governor.connect(citizen2).castVote(proposalId, true);
    await governor.connect(citizen3).castVote(proposalId, true);
    await governor.execute([governor.address], [0], [calldata], "changeQ50");
    expect(await governor.quorum()).to.eq(50);
  });

  it("create fact", async function () {
    expect(await registry.highwaterFact()).to.eq(1);
    expect(await registry.owner()).to.eq(governor.address);
    const calldata =
      "0x244828fe" +
      "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000f69734665654f6e5472616e736665720000000000000000000000000000000000";

    const proposalId = await governor.hashProposal(
      [registry.address],
      [0],
      [calldata],
      "createFact"
    );
    await governor.propose([registry.address], [0], [calldata], "createFact");
    await governor.castVote(proposalId, true);
    await governor.connect(citizen2).castVote(proposalId, true);

    await governor.execute([registry.address], [0], [calldata], "createFact");
    expect(await registry.highwaterFact()).to.eq(2);
  });

  it("addUpdateERC20", async function () {
    expect(await registry.factSetIsValidated(ERC20_1, 7)).to.eq(false);
    const calldata =
      "0x265eb5b7" +
      "000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48" +
      "0000000000000000000000000000000000000000000000000000000000000007";

    const proposalId = await governor.hashProposal(
      [registry.address],
      [0],
      [calldata],
      "addUpdateERC20"
    );
    await governor.propose(
      [registry.address],
      [0],
      [calldata],
      "addUpdateERC20"
    );
    await governor.castVote(proposalId, true);
    await governor.connect(citizen2).castVote(proposalId, true);

    await governor.execute(
      [registry.address],
      [0],
      [calldata],
      "addUpdateERC20"
    );
    expect(await registry.factSetIsValidated(ERC20_1, 7)).to.eq(true);
  });
});
