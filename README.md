<p align="center">
  <img width="500" src="https://user-images.githubusercontent.com/46760063/170324411-ea99e442-6237-4a5d-b1a0-d39fb0d039b4.png"></br>
  <strong>Built for Macro Internal Hackathon</strong></br>
  <strong>23-25 May 2022</strong>
</p>

## Idea
An on-chain, queryable, registry of ERC-20 token audited behaviors.

## Implementation
1. **ERC20Registry:** registry storing audited facts for ERC20s.  
3. **Governor:** governance module responsible to govern registry.
4. **Demo Client Contract** 

## Deployments

- ERC20Registry</br>
  https://goerli.etherscan.io/address/0xCCB7f9a06fCfbDd8A4F0C3F177648aa696eb5506#code
  
- Governor</br>
  https://goerli.etherscan.io/address/0x390c1D7aE1B18183a6E0b59d6D5AE7Efd53b76fE#code

- MockFactory</br>
  https://goerli.etherscan.io/address/0xeD20E56B9EEb8Fc4d076256C2F8B7372b376f265#code


## Detailed Spec
https://www.notion.so/0xmacro/TokenScope-Spec-b6c8cbfd4be94796a11e371e0d94b9fb


## Commands 
```shell
npm run lintAndFormat
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```
