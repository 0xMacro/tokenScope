import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, network, getNamedAccounts } = hre;
  const { deploy, get } = deployments;
  const governor = (await get("Governor")).address;
  console.log(governor);
  const construstorParams = [governor];
  const { deployer0 } = await getNamedAccounts();

  const contract = await deploy("ERC20Registry", {
    from: deployer0,
    args: construstorParams,
    log: true,
    autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
  });

  if (network.name !== "hardhat") {
    try {
      await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: [...construstorParams],
      });
    } catch (err) {
      console.error("Etherscan verification failed", err);
    }
  }
};

export default func;
func.tags = ["ERC20Registry"];
