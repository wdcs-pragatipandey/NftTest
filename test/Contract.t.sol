// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "../src/TST.sol";

contract TestNFTLocked is Test {
    NFTLocked nftLocked;

    address owner;
    address user1;
    address user2;
    address user3;

    function setUp() public {
        owner = msg.sender;
        user1 = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        user2 = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        user3 = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);

        nftLocked = new NFTLocked();
    }

    function testTokenInitialization() public {
        uint256 expectedSupply = 1000 * 10 ** 18;
        nftLocked.mint(1000);
        assertEq(
            nftLocked.balanceOf(address(this)),
            expectedSupply,
            "Token initialization failed"
        );
    }

    function testTierManagement() public {
        nftLocked.startTier(1);
        assertTrue(nftLocked.tierActiveStatus(1), "Tier 1 should be active");
        nftLocked.endTier(1);
        assertFalse(
            nftLocked.tierActiveStatus(1),
            "Tier 1 should be inactive after ending"
        );
    }

    function testUserRegistration() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        assertTrue(
            nftLocked.isUserRegistered(user1),
            "User registration failed"
        );
    }

    function testNFTURLSetting() public {
        string memory expectedURL = "ipfs://CID/{id}.json";
        nftLocked.setURI(expectedURL);
    }

    function testUserWhitelisting() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user1);
        uint256 whitelistLength = nftLocked.whitelistCounter(user1);
        assertTrue(whitelistLength == 2, "User whitelisting failed");
    }

    function testUserRemoveWhitelisting() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user1);
        nftLocked.removeWhitelist(user1);
        uint256 whitelistLength = nftLocked.whitelistCounter(user1);
        assertTrue(whitelistLength == 0, "User whitelisting failed");
    }

    function testPurchaseNFTTier1() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user2, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user2);
        nftLocked.startTier(1);
        vm.prank(user2);
        // uint256 initialBalance = user2.balance;
        uint256 purchasePrice = 0.02 ether;
        vm.deal(user2,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
        // assertEq(
        //     user2.balance,
        //     initialBalance - purchasePrice,
        //     "NFT purchase in Tier 1 failed"
        // );
    }

    function testPurchaseNFTTier1Black() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user2, NFTLocked.NFTType.Black, tiers);
        nftLocked.whitelistUser(user2);
        nftLocked.startTier(1);
        vm.prank(user2);
        // uint256 initialBalance = user2.balance;
        uint256 purchasePrice = 0.01 ether;
        vm.deal(user2,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Black, 1);
        // assertEq(
        //     user2.balance,
        //     initialBalance - purchasePrice,
        //     "NFT purchase in Tier 1 failed"
        // );
    }

    function testPurchaseNFTTier2() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user1);
        nftLocked.startTier(2);
        vm.prank(user1);
        // uint256 initialBalance = user1.balance;
        uint256 purchasePrice = 0.01 ether;
        vm.deal(user1,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Black, 1);
        // assertEq(
        //     user1.balance,
        //     initialBalance - purchasePrice,
        //     "NFT purchase in Tier 2 failed"
        // );
    }

    function testPurchaseNFTTier2Gold() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Black, tiers);
        nftLocked.whitelistUser(user1);
        nftLocked.startTier(2);
        vm.prank(user1);
        // uint256 initialBalance = user1.balance;
        uint256 purchasePrice = 0.02 ether;
        vm.deal(user1,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
        // assertEq(
        //     user1.balance,
        //     initialBalance - purchasePrice,
        //     "NFT purchase in Tier 2 failed"
        // );
    }

    function testPurchaseNFTWhenTierNotStarted() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user1);
        vm.expectRevert("Invalid tier for purchase");
        vm.prank(user1);
        uint256 purchasePrice = 0.02 ether;
        vm.deal(user1,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
    }

    function testRevertPurchaseNFTTier1WithoutRegistration() public {
        nftLocked.startTier(1);
        vm.expectRevert("User not registered");
        vm.prank(user3);
        uint256 purchasePrice = 0.02 ether;
        vm.deal(user3,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
    }

    function testRevertPurchaseNFTTier2WithoutWhitelisting() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.startTier(2);
        vm.expectRevert("User not whitelisted");
        vm.prank(user1);
        uint256 purchasePrice = 0.01 ether;
        vm.deal(user1,purchasePrice);
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Black, 1);
    }

    function testNFTRedemption() public {
        nftLocked.startTier(3);
        vm.prank(user2);
        nftLocked.redeem();
    }

    function testNFTRedemptionintier4() public {
        nftLocked.startTier(4);
        vm.prank(user2);
        nftLocked.redeem();
    }

    function testNFTRedemptionintier5() public {
        nftLocked.startTier(5);
        vm.prank(user2);
        nftLocked.redeem();
    }

    function testNFTRedemptionifTier3skip() public {
        nftLocked.startTier(4);
        vm.prank(user2);
        nftLocked.redeem();
    }

    receive() external payable {}

    function testWithdrawal() public {
        uint256 initialBalance = user1.balance;
        vm.deal(address(this), initialBalance);
        nftLocked.withdraw();
        // assertTrue(
        //     address(this).balance > initialOwnerBalance,
        //     "Withdrawal failed"
        // );
    }
}
