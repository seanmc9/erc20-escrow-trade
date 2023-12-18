// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract ERC20EscrowTrade {
    address public immutable party1;
    address public immutable party2;
    IERC20 public immutable currency1; // the currency that party1 is sending
    IERC20 public immutable currency2; // the currency that party2 is sending
    uint256 public immutable amt1; // amount of currency1 that party1 will be sending
    uint256 public immutable amt2; // amount of currency2 that party2 will be sending

    bool public tradeHasExecuted;

    error YouAreNotAParty();
    error CannotBackoutOnceExecuted();
    error TradeHasAlreadyExecuted();
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
    // Cannot do once the trade has been executed.
    function backout() public {
        if ((msg.sender != party1) && (msg.sender != party2)) revert YouAreNotAParty();
        if (tradeHasExecuted) revert CannotBackoutOnceExecuted();
        
        IERC20 currencyToWithdraw = (msg.sender == party1) ? currency1 : currency2;

        SafeERC20.safeTransfer(currencyToWithdraw, msg.sender, currencyToWithdraw.balanceOf(address(this)));
    }

    ////////////////////

    // EXECUTING

    // Send escrowed funds to their respective beneficiaries.
    // Can only execute once.
    // In order to execute both parties have to have put at least their respective amounts in.
    function executeTrade() public {
        if ((msg.sender != party1) && (msg.sender != party2)) revert YouAreNotAParty();
        if (tradeHasExecuted) revert TradeHasAlreadyExecuted();
        if (currency1.balanceOf(address(this)) < amt1) revert Party1HasNotDepositedEnough();
        if (currency2.balanceOf(address(this)) < amt2) revert Party2HasNotDepositedEnough();

        tradeHasExecuted = true;

        SafeERC20.safeTransfer(currency1, party2, amt1);
        SafeERC20.safeTransfer(currency2, party1, amt2);
    }

    ////////////////////

    // WITHDRAWING EXTRA

    // For if either party accidentally sent in too much at any point.
    // If the trade has been executed, anything left is extra, if it hasn't yet then anything over the calling party's amount is extra.
    // Can call at any point.
    function withdrawExtra() public {
        if ((msg.sender != party1) && (msg.sender != party2)) revert YouAreNotAParty();
        
        IERC20 currencyToWithdraw = (msg.sender == party1) ? currency1 : currency2;
        uint256 overThisIsExtra = tradeHasExecuted ? 0 : ((msg.sender == party1) ? amt1 : amt2);
        if (currencyToWithdraw.balanceOf(address(this)) <= overThisIsExtra) revert ThereIsNoExtra();

        SafeERC20.safeTransfer(currencyToWithdraw, msg.sender, (currencyToWithdraw.balanceOf(address(this)) - overThisIsExtra));
    }
}
