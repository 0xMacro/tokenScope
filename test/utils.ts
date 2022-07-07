import { ethers } from "hardhat";
import { BigNumber, EventFilter } from "ethers";

export enum OptionalBool {
  UNSET = 0,
  FALSE = 1,
  TRUE = 2
};

export const IS_REGISTERED: BigNumber = BigNumber.from(0);
export const IS_VALID_ERC20: BigNumber = BigNumber.from(1);


