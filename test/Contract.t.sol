// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
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
        contractNFTLocked = new NFTLocked("goldNFTUrl", "blackNFTUrl");
    }

    function testConstructor() public {
        assertEq(contractNFTLocked.goldNFTUrl(), "goldNFTUrl");
        assertEq(contractNFTLocked.blackNFTUrl(), "blackNFTUrl");
    }

    function testRegisterUser_AlreadyRegistered() public {
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, [1]);
        vm.expectRevert("User already registered");
        contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Black, [2]);
    }

    // function testRegisterUser_InvalidTier() public {
    //     vm.expectRevert("Invalid tier");
    //     contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, 3);
    // }

    function testStartTier_ValidTier() public {
        contractNFTLocked.startTier(1);
        assertEq(contractNFTLocked.tierStartTimes(1), block.timestamp);
    }

    function testStartTier_InvalidTier() public {
        vm.expectRevert("Invalid tier");
        contractNFTLocked.startTier(0);
    }

    function testStartTier_TierAlreadyStarted() public {
        contractNFTLocked.startTier(1);
        vm.expectRevert("Tier already started");
        contractNFTLocked.startTier(1);
    }

    // function testWhitelistUser_ValidWhitelist() public {
    //     contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, [1]);
    //     contractNFTLocked.whitelistUser(user1);
    //     assertEq(contractNFTLocked.tierWhitelist(user1), [1]);
    // }

    // function testPurchaseNFT_UserNotRegistered() public {
    //     contractNFTLocked.whitelistUser(user1);
    //     contractNFTLocked.startTier(1);
    //     vm.expectRevert("User not registered");
    //     contractNFTLocked.purchaseNFT{value: 0.02 ether}(
    //         NFTLocked.NFTType.Gold
    //     );
    // }

    // function testRemoveWhitelist_ValidRemove() public {
    //     contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, [1]);
    //     contractNFTLocked.whitelistUser(user1);
    //     contractNFTLocked.removeWhitelist(user1);
    //     assertEq(contractNFTLocked.tierWhitelist(user1), 0);
    // }

    // function testPurchaseNFT_Basic() public {
    //     try
    //         contractNFTLocked.purchaseNFT{value: 0.03 ether}(
    //             NFTLocked.NFTType.Gold
    //         )
    //     {
    //         console.log("PurchaseNFT succeeded");
    //     } catch Error(string memory reason) {
    //         console.log("PurchaseNFT reverted with reason:", reason);
    //     }
    // }

    // function testPurchaseNFT_RegistrationAndWhitelisting() public {
    //     contractNFTLocked.registerUser(user1, NFTLocked.NFTType.Gold, [1]);
    //     contractNFTLocked.whitelistUser(user1);
    //     assertTrue(
    //         contractNFTLocked.isUserRegistered(user1),
    //         "User1 is not registered"
    //     );
    //     contractNFTLocked.startTier(1);
    //     try
    //         contractNFTLocked.purchaseNFT{value: 0.02 ether}(
    //             NFTLocked.NFTType.Gold
    //         )
    //     {
    //         console.log("PurchaseNFT succeeded");
    //     } catch Error(string memory reason) {
    //         console.log("PurchaseNFT reverted with reason:", reason);
    //     }
    // }

    // function testRedeemLogic() public {
    //     address user = address(0x123);
    //     contractNFTLocked.registerUser(user, NFTLocked.NFTType.Gold, 1);

    //     contractNFTLocked.startTier(1);
    //     contractNFTLocked.startTier(2);
    //     contractNFTLocked.startTier(3);
    //     uint256 initialTSTBalance = contractNFTLocked.balanceOf(
    //         user,
    //         contractNFTLocked.()
    //     );
    //     contractNFTLocked.redeem();
    //     uint256 expectedTSTIncrease = 400;
    //     uint256 finalTSTBalance = contractNFTLocked.balanceOf(
    //         user,
    //         contractNFTLocked.TST()
    //     );
    //     assertEq(
    //         finalTSTBalance,
    //         initialTSTBalance + expectedTSTIncrease,
    //         "User's TST balance should increase after redeeming"
    //     );
    // }
}
