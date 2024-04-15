// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestToken is ERC20, Ownable {
    constructor() ERC20("TestToken", "TST") Ownable(msg.sender) {}

    function mint(uint256 amount) public onlyOwner {
        uint256 _amount = amount * 10 ** 18;
        _mint(msg.sender, _amount);
    }
}
