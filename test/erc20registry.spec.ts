import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, EventFilter } from "ethers";
import { beforeEach } from "mocha";
import { ERC20Registry } from "../typechain";
import {
  OptionalBool,
  IS_REGISTERED,
  IS_VALID_ERC20
} from "./utils";


describe("ERC20Registry", function () {
  let deployedAtBlock: BigNumber;

  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;
  let members: SignerWithAddress[];
  let tokenAAddress: string;
  let tokenBAddress: string;

  let registry: ERC20Registry;

  beforeEach(async function () {
    [owner, alice, bob, ...members] = await ethers.getSigners();

    // We just need dummy addresses to use for testing tokens
    tokenAAddress = members[0].address;
    tokenBAddress = members[1].address;

    let registryFactory = await ethers.getContractFactory("ERC20Registry");
    registry = <ERC20Registry>await registryFactory.deploy(owner.address);
    await registry.deployed();
  });

  it("Constructor creates and emits expected facts", async () => {
    // Query all ERC20FactCreated events from constructor
    let events = await registry.queryFilter(
      registry.filters.ERC20FactCreated(),
      registry.deployTransaction.blockNumber?.valueOf()
    );

    // Should be 2 of them
    expect(events.length).to.eq(2);

    // Should have these specific ids
    let factIds: BigNumber[] = events.map((e) => e.args.factId);
    expect(factIds).to.eql([IS_REGISTERED, IS_VALID_ERC20]);

    // Should have these specific codes
    let factCodes: string[] = events.map((e) => e.args.code);
    expect(factCodes).to.eql(["IS_REGISTERED", "IS_VALID_ERC20"]);

    // Highwater matches
    expect(await registry.highwaterFactId()).to.eq(IS_VALID_ERC20);
  });


  describe("Registry Administration", () => {
    it("fact creation works", async () => {
      // facts 0, 1 exist
      expect(await registry.highwaterFactId()).to.eq(IS_VALID_ERC20);

      // Create the next fact: 2
      const NEW_FACT = 2;
      await expect(registry.createFact("NEW_FACT"))
        .to.emit(registry, "ERC20FactCreated")
        .withArgs(NEW_FACT, "NEW_FACT");

      // Confirm the new fact is the present highwater
      expect(await registry.highwaterFactId()).to.eq(NEW_FACT);
    });

    it("can create more than 256 facts per token", async () => {
      // fact ids 0-1 exist. Generate 2-255 for the full 256 facts.
      for (let i = 2; i < 256; i++) {
        await expect(registry.createFact(`Fact${i}`)).to.not.be.reverted;
      }

      // Confirm highwater is 255 (256 facts exist)
      expect(await registry.highwaterFactId()).to.eq(255);

      // The 257th fact should not revert
      await expect(registry.createFact("THIS_IS_FINE")).to.not.be.reverted;

      // Confirm highwater is 256 (257 facts exist)
      expect(await registry.highwaterFactId()).to.eq(256);
    });

    it("token registration works", async () => {
      // Create some more facts to work with
      await registry.createFact("FACT_ID_2");
      const FACT_ID_2 = await registry.highwaterFactId();

      await registry.createFact("FACT_ID_3");
      const FACT_ID_3 = await registry.highwaterFactId();

      // ADD REGISTRATION

      // Confirm tokenA is unregistered
      expect(await registry.tokenIsRegistered(tokenAAddress)).to.eq(false);

      // Register: expect emit of new facts
      // The IS_REGISTERED standard fact - which sets the first bit -
      // is always applied, turning 2 into a 3.
      await expect(registry.addUpdateERC20(tokenAAddress, [FACT_ID_2], [OptionalBool.TRUE]))
        .to.emit(registry, "ERC20TokenAddUpdate")
        .withArgs(tokenAAddress, true, [FACT_ID_2], [OptionalBool.TRUE]);

      // Confirm tokenA is registered, and has expected factSet
      expect(await registry.tokenIsRegistered(tokenAAddress)).to.eq(true);

      // UPDATE REGISTRATION

      // Confirm we can update a token registry entry
      await expect(registry.addUpdateERC20(tokenAAddress, [FACT_ID_3], [OptionalBool.FALSE]))
        .to.emit(registry, "ERC20TokenAddUpdate")
        .withArgs(tokenAAddress, false, [FACT_ID_3], [OptionalBool.FALSE]);

      // Re-confirm tokenA is registered, and has expected factSet
      expect(await registry.tokenIsRegistered(tokenAAddress)).to.eq(true);
    });

    it("reverts if a fact is invalid", async () => {
      // Try to register with a fact that hasn't been created yet.
      await expect(
        registry.addUpdateERC20(tokenAAddress, [10], [OptionalBool.TRUE])
      ).to.be.revertedWith("InvalidFact(10, 1)");
    });
  });

  describe("Registry Querying", () => {
    it("works as expected", async () => {
      // Create some more facts to work with
      await registry.createFact("FACT_ID_2");
      let FACT_ID_2 = await registry.highwaterFactId();

      await registry.createFact("FACT_ID_3");
      let FACT_ID_3 = await registry.highwaterFactId();

      await registry.createFact("FACT_ID_4");
      let FACT_ID_4 = await registry.highwaterFactId();

      // TokenA facts
      await registry.addUpdateERC20(
        tokenAAddress,
        [FACT_ID_2, FACT_ID_3, FACT_ID_4],
        [OptionalBool.TRUE, OptionalBool.FALSE, OptionalBool.UNSET]
      );

      // query multiple facts for tokenA
      expect(
        await registry.queryTokenFacts(tokenAAddress, [
          IS_REGISTERED,
          IS_VALID_ERC20,
          FACT_ID_2,
          FACT_ID_3,
          FACT_ID_4
        ])
      ).to.eql([
        OptionalBool.TRUE,
        OptionalBool.UNSET,
        OptionalBool.TRUE,
        OptionalBool.FALSE,
        OptionalBool.UNSET
      ]);

      // TokenB facts
      await registry.addUpdateERC20(
        tokenBAddress,
        [FACT_ID_3, FACT_ID_4],
        [OptionalBool.TRUE, OptionalBool.FALSE]
      );

      // query multiple facts for tokenB
      expect(
        await registry.queryTokenFacts(tokenBAddress, [
          IS_REGISTERED,
          IS_VALID_ERC20,
          FACT_ID_2,
          FACT_ID_3,
          FACT_ID_4
        ])
      ).to.eql([
        OptionalBool.TRUE,
        OptionalBool.UNSET,
        OptionalBool.UNSET,
        OptionalBool.TRUE,
        OptionalBool.FALSE
      ]);
    });
  });
});
