import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { beforeEach } from "mocha";
import { ERC20Registry, MockFactory } from "../typechain";

describe("MockFactory", function () {
  let owner: SignerWithAddress;
  let members: SignerWithAddress[];
  let tokenAAddress: string;
  let tokenBAddress: string;

  let registry: ERC20Registry;
  let factory: MockFactory;

  beforeEach(async function () {
    [owner, ...members] = await ethers.getSigners();

    // We just need dummy addresses to use for testing tokens
    tokenAAddress = members[0].address;
    tokenBAddress = members[1].address;

    const registryFactory = await ethers.getContractFactory("ERC20Registry");
    registry = <ERC20Registry>await registryFactory.deploy(owner.address);
    await registry.deployed();

    const factoryFactory = await ethers.getContractFactory("MockFactory");
    factory = <MockFactory>(
      await factoryFactory.deploy(owner.address, registry.address)
    );
    await factory.deployed();
  });

  describe("Create new Pool", () => {
    it("does not allow invalid tokens in pool", async () => {
      // TokenA factSet is 2:
      // - IS_VALID_ERC20 = 1 << 1
      await registry.addUpdateERC20(tokenAAddress, 2);

      // TokenA is valid ERC20, TokenB is not
      expect(await registry.tokenIsValidERC20(tokenAAddress)).to.equal(true);
      expect(await registry.tokenIsValidERC20(tokenBAddress)).to.equal(false);

      // createPair should fail, TokenB is not a valid ERC20
      await expect(
        factory.createPair(tokenAAddress, tokenBAddress)
      ).to.be.revertedWith("Token B is not a valid ERC20 implementation");
    });

    it("creates pool for valid token pair", async () => {
      // TokenA factSet is 2:
      // - IS_VALID_ERC20 = 1 << 1
      await registry.addUpdateERC20(tokenAAddress, 2);

      // TokenB factSet is 2:
      // - IS_VALID_ERC20 = 1 << 1
      await registry.addUpdateERC20(tokenBAddress, 2);

      expect(await registry.tokenIsValidERC20(tokenAAddress)).to.equal(true);
      expect(await registry.tokenIsValidERC20(tokenBAddress)).to.equal(true);

      // createPair should be executed, both tokens are valid ERC20
      await expect(factory.createPair(tokenAAddress, tokenBAddress)).to.emit(
        factory,
        "PairCreated"
      );
    });
  });
});
