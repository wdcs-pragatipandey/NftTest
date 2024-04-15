// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import "../src/TST.sol";

contract DeployToken is Script {
  
    uint256 public deployerKey;

    function run() external returns (TestToken) {
        deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        TestToken Token = new TestToken();
        vm.stopBroadcast();
        return Token;
    }
}
