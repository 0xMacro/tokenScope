import { expect } from "chai";
import { ethers } from "hardhat";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import type { Governor } from "../typechain/Governor";
import { BigNumber } from "ethers";

describe("Governor ", function () {
  let governor: Governor;
  let citizen1: SignerWithAddress;
  let citizen2: SignerWithAddress;
  let citizen3: SignerWithAddress;
  const ERC20_1 = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const ERC20_2 = "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984";
  before(async function () {
    [citizen1, citizen2, citizen3] = await ethers.getSigners();
    const Governor = await ethers.getContractFactory("Governor");
    governor = <Governor>await Governor.deploy(citizen1.address);
    await governor.deployed();
  });

  it("Setup check ", async function () {
    expect(await governor.members(citizen1.address)).to.eq(true);
    expect(await governor.members(citizen2.address)).to.eq(false);
    expect(await governor.totalMembers()).to.eq(1);
  });
});
