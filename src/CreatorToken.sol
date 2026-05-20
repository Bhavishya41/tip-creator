// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreatorToken is ERC20, Ownable {
    // We pass the Factory address to the Ownable constructor
    constructor(
        string memory name,
        string memory symbol,
        address factory
    ) ERC20(name, symbol) Ownable(factory) {}

    // Only the Factory (the owner) can mint tokens during a tip
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
