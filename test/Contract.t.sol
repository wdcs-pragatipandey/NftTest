// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {NFTLocked} from "../src/NFT.sol";

contract NFTLockedTest is Test {
    NFTLocked public nft;

    string public _goldNFTUrl = "gold";
    string public _blackNFTUrl = "black";

    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        nft = new NFTLocked(_goldNFTUrl, _blackNFTUrl);
        uint256 ownerBalance = nft.balanceOf(owner, 0);
        assertEq(ownerBalance, 10000 * 10 ** 18);
    }

    function testRegisterUser() external {
        vm.expectRevert("User already registered");
        vm.expectRevert("Invalid tier");
        nft.registerUser(user, NFTLocked.NFTType.Gold, 1);
        NFTLocked.Register memory userNFT = nft.userNFTs(user);
        assertEq(userNFT(user).nftType, NFTLocked.NFTType.Gold);
        assertEq(userNFT(user).tier, 1);
    }

    function testWhitelistUser() external {
        vm.prank(owner);
        // vm.expectRevert(CustomError.selector);
        vm.expectRevert("Invalid tier");
        nft.registerUser(user, NFTLocked.NFTType.Gold, 1);
        nft.whitelistUser(user);
        uint256 whitelistTier = nft.tierWhitelist(user);
        assertEq(whitelistTier, 1);
    }

    // function testRevertsWhitelistingUser() external {
    //     nft.registerUser(user, NFTLocked.NFTType.Gold, 1);
    //     vm.expectRevert("Invalid tier");
    //     nft.whitelistUser(user);
    // }

    function testPurchase() external {
        vm.warp(block.timestamp);
        nft.registerUser(user, NFTLocked.NFTType.Gold, 1);
        nft.whitelistUser(user);
        vm.expectRevert("Invalid tier");
        nft.purchaseNFT{value: 0.02 ether}(NFTLocked.NFTType.Gold);
    }

    function testStartTier() external {
        vm.warp(block.timestamp);
        vm.prank(owner);
        vm.expectRevert("Invalid tier");
        vm.expectRevert("Tier already started");
        nft.startTier(1);
        uint256 startTier = nft.tierStartTimes;
        assertEq(startTier, block.timestamp);
    }

    function testRedeem() external {
        vm.expectRevert("No tier started yet");
        vm.expectRevert("Invalid tier for purchase");
        nft.redeem();
    }

    function testWithdraw() external{
        vm.prank(owner);
        nft.withdraw();
    }

    function testRemovewhitelist() public {
        vm.prank(owner);
        nft.removeWhitelist(user);
        uint256 whitelistTier = nft.tierWhitelist(user);
        assertEq(whitelistTier, 0);
    }


}
