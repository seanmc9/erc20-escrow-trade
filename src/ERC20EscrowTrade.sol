// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract ERC20EscrowTrade {
    address public party1;
    address public party2;
    IERC20 public currency1; // the currency that party1 is sending
    IERC20 public currency2; // the currency that party2 is sending
    uint256 public amt1; // amount of currency1 that party1 will be sending
    uint256 public amt2; // amount of currency2 that party2 will be sending

    bool party1HasExecuted;
    bool party2HasExecuted;

    error YouAreNotParty1();
    error YouAreNotParty2();
    error NeitherPartyCanBackout();
    error Party1HasAlreadyExecuted();
    error Party2HasAlreadyExecuted();
    error Party1HasNotDepositedEnough();
    error Party2HasNotDepositedEnough();
    error ThereIsNoExtra();

    constructor(address party1_, address party2_, IERC20 currency1_, IERC20 currency2_, uint256 amt1_, uint256 amt2_) {
        party1 = party1_;
        party2 = party2_;
        currency1 = currency1_;
        currency2 = currency2_;
        amt1 = amt1_;
        amt2 = amt2_;
    }

    ////////////////////

    // START BY EACH PARTY SENDING THEIR AMOUNT OF THEIR TOKEN TO THIS CONTRACT (bc all my homies hate approval flows)

    ////////////////////

    // BACKING OUT

    // Taking all money that you have put into the contract out.
    // Cannot do once 1 party has executed.
    // Reasoning for why you can't back out once 1 party has executed:
    //  - if someone has executed and you are the executor, your funds are now locked for the other person to take
    //  - if someone has executed and you are not the executor, your funds have been taken

    function backoutParty1() public {
        if (msg.sender != party1) revert YouAreNotParty1();
        if (party1HasExecuted || party2HasExecuted) revert NeitherPartyCanBackout();
        SafeERC20.safeTransfer(currency1, party1, currency1.balanceOf(address(this)));
    }

    function backoutOwnParty2() public {
        if (msg.sender != party2) revert YouAreNotParty2();
        if (party1HasExecuted || party2HasExecuted) revert NeitherPartyCanBackout();
        SafeERC20.safeTransfer(currency2, party2, currency2.balanceOf(address(this)));
    }

    ////////////////////

    // EXECUTING

    // Withdrawing the other party's escrowed funds.
    // Once one party executes, neither can back out.
    // Each party can only execute once.
    // In order to execute:
    //  - You must have already put enough in
    //      AND
    //  - The other party must have already put enough in

    function executeTradeParty1() public {
        if (msg.sender != party1) revert YouAreNotParty1();
        if (party1HasExecuted) revert Party1HasAlreadyExecuted();

        if (currency2.balanceOf(address(this)) < amt2) revert Party2HasNotDepositedEnough();
        if ((currency1.balanceOf(address(this)) < amt1) && !party2HasExecuted) {
            revert Party1HasNotDepositedEnough();
        }

        SafeERC20.safeTransfer(currency2, party1, amt2);
        party1HasExecuted = true;
    }

    function executeTradeParty2() public {
        if (msg.sender != party2) revert YouAreNotParty2();
        if (party2HasExecuted) revert Party2HasAlreadyExecuted();

        if (currency1.balanceOf(address(this)) < amt1) revert Party1HasNotDepositedEnough();
        if ((currency2.balanceOf(address(this)) < amt2) && !party1HasExecuted) {
            revert Party2HasNotDepositedEnough();
        }

        SafeERC20.safeTransfer(currency1, party2, amt1);
        party2HasExecuted = true;
    }

    ////////////////////

    // WITHDRAWING EXTRA

    // For if either party accidentally sent in too much at any point.
    // Extra is the amount over the amount you're supposed to send if your counterparty hasn't executed yet, and it's 
    //  the amount over 0 if they have.
    // Can call at any point.

    function withdrawExtraOwnParty1() public {
        if (msg.sender != party1) revert YouAreNotParty1();
        uint256 amtToCompareAgainst = party2HasExecuted ? 0 : amt1;
        if (currency1.balanceOf(address(this)) <= amtToCompareAgainst) revert ThereIsNoExtra();
        SafeERC20.safeTransfer(currency1, party1, (currency1.balanceOf(address(this)) - amtToCompareAgainst));
    }

    function withdrawExtraOwnParty2() public {
        if (msg.sender != party2) revert YouAreNotParty2();
        uint256 amtToCompareAgainst = party1HasExecuted ? 0 : amt2;
        if (currency2.balanceOf(address(this)) <= amtToCompareAgainst) revert ThereIsNoExtra();
        SafeERC20.safeTransfer(currency2, party2, (currency2.balanceOf(address(this)) - amtToCompareAgainst));
    }
}
