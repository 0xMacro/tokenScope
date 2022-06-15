import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { beforeEach } from "mocha";
import { ERC20Registry, MockFactory } from "../typechain";
import {
  OptionalBool,
  IS_REGISTERED,
  IS_VALID_ERC20
} from "./utils";


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
      // Set only TokenA as a valid ERC20
      await registry.addUpdateERC20(tokenAAddress, [IS_VALID_ERC20], [OptionalBool.TRUE]);

      // TokenA is valid ERC20, TokenB is not
      expect(await registry.tokenIsValidERC20(tokenAAddress)).to.equal(OptionalBool.TRUE);
      expect(await registry.tokenIsValidERC20(tokenBAddress)).to.equal(OptionalBool.UNSET);

      // createPair should fail, TokenB is not a valid ERC20
      await expect(
        factory.createPair(tokenAAddress, tokenBAddress)
      ).to.be.revertedWith("Token B is not a valid ERC20 implementation");
    });

    it("creates pool for valid token pair", async () => {
      // Set both tokens as valid ERC20
      await registry.addUpdateERC20(tokenAAddress, [IS_VALID_ERC20], [OptionalBool.TRUE]);
      await registry.addUpdateERC20(tokenBAddress, [IS_VALID_ERC20], [OptionalBool.TRUE]);

      expect(await registry.tokenIsValidERC20(tokenAAddress)).to.equal(OptionalBool.TRUE);
      expect(await registry.tokenIsValidERC20(tokenBAddress)).to.equal(OptionalBool.TRUE);

      // createPair should be executed, both tokens are valid ERC20
      await expect(factory.createPair(tokenAAddress, tokenBAddress)).to.emit(
        factory,
        "PairCreated"
      );
    });
  });
});
