// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CreatorTokenFactory} from "../src/CreatorTokenFactory.sol";
import {CreatorToken} from "../src/CreatorToken.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract CreatorTokenFactoryTest is Test {
    CreatorTokenFactory public factory;
    IERC20 public mockUsd;

    address public treasury;
    address public testFan = address(0x999); // Isolated testing wallet

    function setUp() public {
        // 1. Point dynamically to your live deployed local architecture via .env
        address factoryAddress = vm.envAddress("CONTRACT_ADDRESS");
        address mockUsdAddress = vm.envAddress("MOCK_USD_ADDRESS");

        require(
            factoryAddress != address(0),
            "Error: CONTRACT_ADDRESS not populated in .env"
        );

        // 2. Instantiate references to live contracts
        factory = CreatorTokenFactory(factoryAddress);
        mockUsd = IERC20(mockUsdAddress);
        treasury = vm.envAddress("PROTOCOL_TREASURY");

        // 3. Professional Cheatcode: Force-allocate 1,000 Mock USD to our test user on the local fork
        // This completely bypasses having to deal with interactive web faucets during tests
        deal(mockUsdAddress, testFan, 1000 * 1e18);
    }

    function test_LiveLocalTipAndMintFlow() public {
        string memory creatorHandle = "youtube:@CodyKo";
        uint256 tipAmount = 100 * 1e18; // $100 Mock USD Tip

        // Check original balance allocations
        uint256 startingTreasuryBalance = mockUsd.balanceOf(treasury);

        // 4. Impersonate the test fan account
        vm.startPrank(testFan);

        // Approve factory to pull Mock USD from the fan's balance
        mockUsd.approve(address(factory), tipAmount);

        console.log("Executing live local tipAndMint call...");
        factory.tipAndMint(creatorHandle, tipAmount);

        vm.stopPrank();

        // --- VALIDATE LIVE SYSTEM ECONOMIC ENGINE ---

        // Verify 5% protocol fee routing ($5 out of $100)
        uint256 endingTreasuryBalance = mockUsd.balanceOf(treasury);
        assertEq(
            endingTreasuryBalance - startingTreasuryBalance,
            5 * 1e18,
            "System failed to route 5% fee to treasury"
        );
        console.log("Protocol Fee verified: 5% routed cleanly to treasury.");

        // Verify ERC-20 deployment mapping
        address deployedTokenAddress = factory.handleToToken(creatorHandle);
        assertTrue(
            deployedTokenAddress != address(0),
            "System failed to spawn full deployment contract"
        );
        console.log(
            "Full creator contract deployed to address:",
            deployedTokenAddress
        );

        // Verify fan received bonding curve supply
        uint256 fanCreatorTokenBalance = CreatorToken(deployedTokenAddress)
            .balanceOf(testFan);
        assertGt(
            fanCreatorTokenBalance,
            0,
            "Fan received zero tokens from bonding curve calculation"
        );
        console.log(
            "Fan received raw creator token wei:",
            fanCreatorTokenBalance
        );
    }
}
