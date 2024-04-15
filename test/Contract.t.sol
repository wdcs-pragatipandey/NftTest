// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "../src/TST.sol";

contract TestNFTLocked is Test {
    NFTLocked nftLocked;
    TestToken token;

    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = msg.sender;
        user1 = address(0x01);
        user2 = address(0x02);

        nftLocked = new NFTLocked("gold_nft", "black_nft");
    }

    function testInitialDeployment() public {
        assertEq(address(token.owner()), owner, "Owner should be the deployer");
    }

    function testTokenInitialization() public {
        uint256 expectedSupply = 1000 * 10 ** 18;
        token.mint(1000);
        assertEq(
            token.balanceOf(owner),
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
        string memory expectedURL = "gold_nft";
        nftLocked.setGoldNFTUrl(expectedURL);
        assertEq(
            nftLocked.goldNFTUrl(),
            expectedURL,
            "Gold NFT URL setting failed"
        );
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
        nftLocked.startTier(1);
        uint256 purchasePrice = 0.02 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
    }

    function testPurchaseNFTTier1Black() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user2, NFTLocked.NFTType.Black, tiers);
        nftLocked.startTier(1);
        uint256 purchasePrice = 0.01 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Black, 1);
    }

    function testPurchaseNFTTier2() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user1);
        nftLocked.startTier(2);
        uint256 initialBalance = user1.balance;
        uint256 purchasePrice = 0.01 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Black, 1);
        assertEq(
            user1.balance,
            initialBalance - purchasePrice,
            "NFT purchase in Tier 2 failed"
        );
    }

    function testPurchaseNFTTier2Gold() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Black, tiers);
        nftLocked.whitelistUser(user1);
        nftLocked.startTier(2);
        uint256 initialBalance = user1.balance;
        uint256 purchasePrice = 0.02 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
        assertEq(
            user1.balance,
            initialBalance - purchasePrice,
            "NFT purchase in Tier 2 failed"
        );
    }

    function testPurchaseNFTWhenTierNotStarted() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.whitelistUser(user1);
        uint256 purchasePrice = 0.02 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
    }

    function testRevertPurchaseNFTTier1WithoutRegistration() public {
        nftLocked.startTier(1);
        uint256 purchasePrice = 0.02 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Gold, 1);
    }

    function testRevertPurchaseNFTTier2WithoutWhitelisting() public {
        uint256[] memory tiers = new uint256[](2);
        tiers[0] = 1;
        tiers[1] = 2;
        nftLocked.registerUser(user1, NFTLocked.NFTType.Gold, tiers);
        nftLocked.startTier(2);
        uint256 purchasePrice = 0.01 ether;
        nftLocked.purchaseNFT{value: purchasePrice}(NFTLocked.NFTType.Black, 1);
    }

    function testNFTRedemption() public {
        nftLocked.endTier(2);
        nftLocked.startTier(3);
        nftLocked.redeem();
    }

    function testNFTRedemptionintier4() public {
        nftLocked.endTier(3);
        nftLocked.startTier(4);
        nftLocked.redeem();
    }

    function testNFTRedemptionintier5() public {
        nftLocked.endTier(4);
        nftLocked.startTier(5);
        nftLocked.redeem();
    }

    function testNFTRedemptionifTier3skip() public {
        nftLocked.endTier(3);
        nftLocked.startTier(4);
        nftLocked.redeem();
    }

    function testWithdrawal() public {
        uint256 initialOwnerBalance = address(this).balance;
        nftLocked.withdraw();
        assertTrue(
            address(this).balance > initialOwnerBalance,
            "Withdrawal failed"
        );
    }
}
