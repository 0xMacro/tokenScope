import { expect } from "chai";
import { ethers } from "hardhat";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import type { Governance } from "../typechain/Governance";
import { BigNumber } from "ethers";

describe("Governance", function () {
  let governance: Governance;
  let citizen1: SignerWithAddress;
  let citizen2: SignerWithAddress;
  let citizen3: SignerWithAddress;
  const ERC20_1 = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const ERC20_2 = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984";
  before(async function () {
    [citizen1, citizen2, citizen3] = await ethers.getSigners();
    const Governance = await ethers.getContractFactory("Governance");
    governance = <Governance>await Governance.deploy(citizen1.address);
    await governance.deployed();
  });

  it("Setup check ", async function () {
    expect(await governance.citizens(citizen1.address)).to.eq(true);
    expect(await governance.citizens(citizen2.address)).to.eq(false);
    expect(await governance.totalCitizens()).to.eq(1);
    expect((await governance.hasAttribute(ERC20_1, 1))[0]).to.eq(0);
    expect((await governance.hasAttribute(ERC20_1, 1))[1]).to.eq(4);
  });

  it("Update Vote", async function () {
    await governance.updateVote([
      {
        erc20: ERC20_1,
        attribute: 0,
        support: true,
      },
      {
        erc20: ERC20_1,
        attribute: 1,
        support: false,
      },
      {
        erc20: ERC20_2,
        attribute: 1,
        support: true,
      },
    ]);

    expect((await governance.hasAttribute(ERC20_1, 0))[0]).to.eq(100);
    expect((await governance.hasAttribute(ERC20_1, 0))[1]).to.eq(0);
    expect((await governance.hasAttribute(ERC20_1, 1))[0]).to.eq(0);
    expect((await governance.hasAttribute(ERC20_1, 1))[1]).to.eq(4);
  });
});
