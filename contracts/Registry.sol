//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Governance.sol";

contract Registry is Governance {
    constructor(address _firstCitizen) Governance(_firstCitizen) {}
}
