// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CreatorToken.sol";

contract CreatorTokenFactory {
    using Math for uint256;

    IERC20 public mockUsd;
    address public protocolTreasury;
    uint256 public protocolFeeBPS = 500; // 5%
    uint256 public curveMultiplier = 1e18; // Bonding curve slope

    mapping(string => address) public handleToToken;
    mapping(string => uint256) public handleReserve;
    mapping(string => uint256) public handleSupply;

    constructor(address _mockUsd, address _treasury) {
        mockUsd = IERC20(_mockUsd);
        protocolTreasury = _treasury;
    }

    function tipAndMint(string memory _handle, uint256 _tipAmount) external {
        // 1. Calculate and route the protocol fee
        uint256 fee = (_tipAmount * protocolFeeBPS) / 10000;
        uint256 netTip = _tipAmount - fee;
        mockUsd.transferFrom(msg.sender, protocolTreasury, fee);

        // 2. Route the net tip to the creator's reserve vault (in this contract)
        mockUsd.transferFrom(msg.sender, address(this), netTip);

        // 3. Deploy the token if it doesn't exist yet
        address creatorToken = handleToToken[_handle];
        if (creatorToken == address(0)) {
            // Full deployment of a new contract
            CreatorToken newToken = new CreatorToken(
                _handle,
                _handle,
                address(this)
            );
            creatorToken = address(newToken);
            handleToToken[_handle] = creatorToken;
        }

        // 4. Bonding Curve Math
        uint256 currentReserve = handleReserve[_handle];
        uint256 newReserve = currentReserve + netTip;

        uint256 scaledReserve = newReserve * 1e18;
        uint256 newSupply = Math.sqrt((2 * scaledReserve) / curveMultiplier);

        uint256 currentSupply = handleSupply[_handle];
        uint256 tokensToMint = newSupply - currentSupply;

        // 5. Update State & Mint
        handleReserve[_handle] = newReserve;
        handleSupply[_handle] = newSupply;

        CreatorToken(creatorToken).mint(msg.sender, tokensToMint);
    }
}
