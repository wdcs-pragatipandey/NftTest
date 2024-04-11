// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "forge-std/Test.sol";
import "../src/NFT.sol";
contract NFTLockedTest is Test {
    NFTLocked contractNFTLocked;

    address user1;
    address user2;
    address owner;

    function setUp() public {
        owner = msg.sender;
        user1 = address(0x1);
        user2 = address(0x2);
        contractNFTLocked = new NFTLocked("goldNFTUrl", "blackNFTUrl", 10000);
        contractNFTLocked.balanceOf(owner, 0);
        assertEq(contractNFTLocked.balanceOf(owner, 0), 10000);
    }

    function testConstructor() public {
        assertEq(contractNFTLocked.goldNFTUrl(), "goldNFTUrl");
        assertEq(contractNFTLocked.blackNFTUrl(), "blackNFTUrl");
        assertEq(contractNFTLocked.amount(), 10000);
    }

    function testStartTier_ValidTier() public {
        vm.warp(100);
        contractNFTLocked.startTier(1);
        assertEq(contractNFTLocked.tierStartTimes(1), block.timestamp);
    }

    function testStartTier_InvalidTier() public {
        vm.expectRevert("Invalid tier");
        contractNFTLocked.startTier(0);
    }

    function testStartTier_AlreadyStarted() public {
        vm.warp(100);
        contractNFTLocked.startTier(1);
        vm.expectRevert("Tier already started");
        contractNFTLocked.startTier(1);
    }

    function testRegisterUser_ValidRegistration() public {
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 1);

        // assertEq(
        //     contractNFTLocked.userNFTs(user1).nftType,
        //     NFTLocked.NFTType.Gold
        // );
        // assertEq(contractNFTLocked.userNFTs(user1).tier, 1);
    }

    function testRegisterUser_AlreadyRegistered() public {
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 1);
        vm.expectRevert("User already registered");
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Black, 2);
    }

    function testRegisterUser_InvalidTier() public {
        vm.expectRevert("Invalid tier");
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 3);
    }

    function testPurchaseNFT_ValidPurchaseTier1Gold_WithinLimit() public {
        vm.deal(user1, 0.02 ether);
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 1);
        contractNFTLocked.startTier(1);
        contractNFTLocked.whitelistUser(user1);
        contractNFTLocked.purchaseNFT(NFTLocked.NFTType.Gold);
        assertEq(
            contractNFTLocked.balanceOf(user1, uint256(NFTLocked.NFTType.Gold)),
            1
        );
        assertEq(contractNFTLocked.tier1NFTCount(user1), 1);
    }

    function testWhitelistUser_ValidUser() public {
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 1);
        contractNFTLocked.whitelistUser(user1);
        assertEq(contractNFTLocked.tierWhitelist(user1), 1);
    }

    function testWhitelistUser_AlreadyWhitelisted() public {
        contractNFTLocked.whitelistUser(user1);
        contractNFTLocked.whitelistUser(user1);
        vm.expectRevert("User already whitelisted");
    }

    function testWhitelistUser_NotRegisteredUser() public {
        contractNFTLocked.whitelistUser(user2);
        vm.expectRevert("User not registered");
    }

    function testWhitelistUser_InvalidTier() public {
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 3);
        contractNFTLocked.whitelistUser(user1);
        vm.expectRevert("Invalid tier");
    }

    function testRemoveWhitelist_ValidRemoval() public {
        contractNFTLocked.removeWhitelist(user1);
        assertEq(contractNFTLocked.tierWhitelist(user1), 0);
    }

    function testRemoveWhitelist_NotWhitelisted() public {
        contractNFTLocked.removeWhitelist(user2);
        vm.expectRevert("User not whitelisted");
    }

    function testRedeem_ValidRedemption() public {
        contractNFTLocked.redeem();
    }
}
