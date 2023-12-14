// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract ERC20EscrowTrade {
    address public party1;
    address public party2;
    IERC20 public currency1;
    IERC20 public currency2;
    uint256 public amt1; // amount of currency1 that party1 will be sending
    uint256 public amt2; // amount of currency2 that party2 will be sending

    bool party1IsDeposited;
    bool party2IsDeposited;
    bool party1IsWithdrawn;
    bool party2IsWithdrawn;

    error YouAreNotParty1();
    error YouAreNotParty2();
    error YouNeedMoreCurrency1();
    error YouNeedMoreCurrency2();
    error BothPartiesMustBeDeposited();
    error BothPartiesMustBeWithdrawn();
    error YouHaveAlreadyDesposited();
    error YouHaveAlreadyWithdrawn();

    constructor(address party1_, address party2_, IERC20 currency1_, IERC20 currency2_, uint256 amt1_, uint256 amt2_) {
        party1 = party1_;
        party2 = party2_;
        currency1 = currency1_;
        currency2 = currency2_;
        amt1 = amt1_;
        amt2 = amt2_;
    }

    function depositParty1() public {
        if (msg.sender != party1) revert YouAreNotParty1();
        if (currency1.balanceOf(msg.sender) < amt1) revert YouNeedMoreCurrency1();
        if (party1IsDeposited) revert YouHaveAlreadyDeposited();
        SafeERC20.safeTransferFrom(currency1, msg.sender, address(this), amt1);
        party1IsDeposited = true;
    }

    function depositParty2() public {
        if (msg.sender != party2) revert YouAreNotParty2();
        if (currency2.balanceOf(msg.sender) < amt2) revert YouNeedMoreCurrency2();
        if (party2IsDeposited) revert YouHaveAlreadyDeposited();
        SafeERC20.safeTransferFrom(currency2, msg.sender, address(this), amt2);
        party2IsDeposited = true;
    }

    function withdrawParty1() public {
        if (msg.sender != party1) revert YouAreNotParty1();
        if (!(party1IsDeposited && party2IsDeposited)) revert BothPartiesMustBeDeposited();
        if (party1IsWithdrawn) revert YouHaveAlreadyWithdrawn();
        SafeERC20.safeTransfer(currency2, party1, amt2);
        party1IsWithdrawn = true;
    }

    function withdrawParty2() public {
        if (msg.sender != party2) revert YouAreNotParty2();
        if (!(party1IsDeposited && party2IsDeposited)) revert BothPartiesMustBeDeposited();
        if (party2IsWithdrawn) revert YouHaveAlreadyWithdrawn();
        SafeERC20.safeTransfer(currency1, party2, amt1);
        party2IsWithdrawn = true;
    }

    function withdrawExtra1() public {
        if (msg.sender != party1) revert YouAreNotParty1();
        if (!(party1IsWithdrawn && party2IsWithdrawn)) revert BothPartiesMustBeWithdrawn();
        SafeERC20.safeTransfer(currency1, party1, currency1.balanceOf(address(this)));
    }

    function withdrawExtra2() public {
        if (msg.sender != party2) revert YouAreNotParty2();
        if (!(party1IsDeposited && party2IsDeposited)) revert BothPartiesMustBeWithdrawn();
        SafeERC20.safeTransfer(currency2, party2, currency2.balanceOf(address(this)));
    }

}
