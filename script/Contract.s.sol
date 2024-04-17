// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "../src/NFT.sol";

contract DeployNFT is Script {
    // string public _goldNFTUrl = "gold";
    // string public _blackNFTUrl = "black";

    uint256 public deployerKey;

    function run() external returns (NFTLocked) {
        deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        NFTLocked ourToken = new NFTLocked();
        vm.stopBroadcast();
        return ourToken;
    }
}
