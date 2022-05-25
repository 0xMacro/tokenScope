import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, network, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const paul = "0xd67314eCc432c3886c85d3BD0eE4DfC68463E697";
  const baran = "0xDD1DC3e4D8C1b5FA806567F98c968DFC9E51390A";
  const { abhi0, abhi1, abhi2 } = await getNamedAccounts();
  const construstorParams = [[60], [abhi0, abhi1, abhi2, paul, baran]];

  const contract = await deploy("Governor", {
    from: abhi0,
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
func.tags = ["Governor"];
