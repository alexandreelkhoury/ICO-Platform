// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./MyToken.sol";

contract MyTokenAdvancedV2 is MyTokenAdvanced {
    // New staking function 
    function stakeTokens(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Sender does not have enough balance.");
        require(amount > 0, "Amount cannot be zero.");
        setBalance(msg.sender, balanceOf(msg.sender) - amount);
        staked[msg.sender] += amount;
        stakedFromTS[msg.sender] += amount;
        stakingTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }
}