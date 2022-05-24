import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, EventFilter } from "ethers";
import { ethers } from "hardhat";
import { beforeEach } from "mocha";
import { ERC20Registry } from "../typechain";

describe("ERC20Registry", function () {
  let deployedAtBlock: BigNumber;

  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;
  let members: SignerWithAddress[];
  let tokenAAddress: string;
  let tokenBAddress: string;

  let IS_REGISTERED: number = 0;
  let IS_VALID_ERC20: number = 1;
  
  let registry: ERC20Registry;

  beforeEach(async function() {
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
    let factIds: number[] = events.map((e) => e.args.fact);
    expect(factIds).to.have.members([0, 1]);

    // Should have these specific codes
    let factCodes: string[] = events.map((e) => e.args.code);
    expect(factCodes).to.have.members(
      [
        'IS_REGISTERED',
        'IS_VALID_ERC20',
      ]
    );

    // Highwater matches
    expect(await registry.highwaterFact()).to.eq(1);
  });

  describe("Utility Conversion Methods", () => {
    it("factsToFactSet() works", async () => {
      // b0 = 1
      expect(await registry.factsToFactSet([0])).to.eq(1);

      // b101100 = 44 
      expect(await registry.factsToFactSet([5, 3, 2])).to.eq(44);

      // b1000000000000000000000101 = 16777221
      expect(await registry.factsToFactSet([24, 2, 0])).to.eq(16777221);
    });

    it("factSetToFacts() works", async () => {
      // 1 = b0
      expect(await registry.factSetToFacts(1)).to.have.members([0]);

      // 44 = b101100
      expect(await registry.factSetToFacts(44)).to.have.members([5, 3, 2]);

      // 16777221 = b1000000000000000000000101
      expect(await registry.factSetToFacts(16777221)).to.have.members([24, 2, 0]);
    });
  })

  describe("Registry Administration", () => {
    it("fact creation works", async () => {
      // facts 0, 1 exist
      expect(await registry.highwaterFact()).to.eq(1);

      // Create the next fact: 2
      await expect(registry.createFact('NEW_FACT')).
        to.emit(registry, "ERC20FactCreated").withArgs(2, "NEW_FACT");

      // Confirm fact 2 is the present highwater
      expect(await registry.highwaterFact()).to.eq(2);
    });

    it("can create up to 256 facts per token", async () => {
      // fact ids 0-1 exist. Generate 2-255 for the full 256 facts.
      for(let i = 2; i < 256; i++) {
        await expect(registry.createFact(`Fact${i}`)).to.not.be.reverted;
      }

      // Confirm highwater is 255
      expect(await registry.highwaterFact()).to.eq(255);

      // The 257th fact should revert
      await expect(registry.createFact("NOPE")).
        to.be.revertedWith("MAX_FACTS_REACHED");
    });

    it("token registration works", async () => {

      // Create some more facts to work with
      await registry.createFact("FACT_ID_2");
      await registry.createFact("FACT_ID_3");

      // ADD REGISTRATION

      // Confirm tokenA is unregistered
      expect(await registry.tokenIsRegistered(tokenAAddress)).to.eq(false);

      // Register: expect emit of new facts
      // The IS_REGISTERED standard fact - which sets the first bit - 
      // is always applied, turning 2 into a 3.
      await expect(registry.addUpdateERC20(tokenAAddress, 2)).
        to.emit(registry, "ERC20ValidatedFacts").withArgs(tokenAAddress, 3);

      // Confirm tokenA is registered, and has expected factSet
      expect(await registry.tokenIsRegistered(tokenAAddress)).to.eq(true);
      expect(await registry.tokenFacts(tokenAAddress)).to.eq(3);

      // UPDATE REGISTRATION

      // Confirm we can update a token registry entry
      await expect(registry.addUpdateERC20(tokenAAddress, 4)).
        to.emit(registry, "ERC20ValidatedFacts").withArgs(tokenAAddress, 5);

      // Re-confirm tokenA is registered, and has expected factSet
      expect(await registry.tokenIsRegistered(tokenAAddress)).to.eq(true);
      expect(await registry.tokenFacts(tokenAAddress)).to.eq(5);
    });

    it("reverts if a fact is invalid", async () => {
      // Try to register with a fact that hasn't been created yet.
      // Only 7 facts have been created, so the 8th is b10000000 = 128
      await expect(registry.addUpdateERC20(tokenAAddress, 128)).
        to.be.revertedWith("INVALID_FACT_SET");

    });

  });

  describe("Registry Querying", () => {
    it("works as expected", async () => {
      // Create some more facts to work with
      await registry.createFact("FACT_ID_2");

      // TokenA factSet is 2:
      // - IS_VALID_ERC20 = 1 << 1
      await registry.addUpdateERC20(tokenAAddress, 2);

      // TokenB factSet is 4:
      // - FACT_ID_2 = 1 << 2
      await registry.addUpdateERC20(tokenBAddress, 4);

      // TokenA is valid ERC20, TokenB is not
      expect(await registry.tokenIsValidERC20(tokenAAddress)).to.equal(true);
      expect(await registry.tokenIsValidERC20(tokenBAddress)).to.equal(false);

      // via factIsValidated()
      expect(await registry.factsAreValidated(tokenAAddress,
        [
          IS_REGISTERED,
          IS_VALID_ERC20,
        ]
      )).to.equal(true);
      expect(await registry.factsAreValidated(tokenBAddress,
        [
          IS_REGISTERED,
          IS_VALID_ERC20,
        ]
      )).to.equal(false);

      // via factSetIsvalidated()
      // IS_REGISTERED = 1 << 0 = 1 = b01
      // IS_VALID_ERC20 = 1 << 1 = 2 = b10
      // b01 | b10 = b11 = 3
      expect(await registry.factSetIsValidated(tokenAAddress, 3)).to.equal(true);
      expect(await registry.factSetIsValidated(tokenBAddress, 3)).to.equal(false);

    });
  });
});
