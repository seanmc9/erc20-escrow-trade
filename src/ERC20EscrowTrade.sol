// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/IERC20.sol";

contract ERC20EscrowTrade {
    address public party1;
    address public party2;
    IERC20 public currency1;
    IERC20 public currency2;
    uint256 public amt1;
    uint256 public amt2;

    error YouAreNotParty1();
    error YouAreNotParty2();

    constructor(address party1_, address party2_, IERC20 currency1_, IERC20 currency2_, uint256 amt1_, uint256 amt2_) {
        party1 = party1_;
        party2 = party2_;
        currency1 = currency1_;
        currency2 = currency2_;
        amt1 = amt1_;
        amt2 = amt2_;
    }
}
