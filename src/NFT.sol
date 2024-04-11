// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTLocked is ERC1155, Ownable {
    // enum to choose nft type 
    enum NFTType {
        Gold,
        Black,
        Both
    }

    // struct for register Users
    struct Register {
        NFTType nftType;
        uint256 tier;
    }

    // mappings 
    mapping(address => Register) public userNFTs;
    mapping(uint256 => uint256) public tierDurations;
    mapping(address => uint256) public tierWhitelist;
    mapping(address => uint256) public tier1NFTCount;
    mapping(address => uint256) public tier2NFTCount;
    mapping(uint256 => uint256) public tierStartTimes;

    uint256 private constant tier1Duration = 30 minutes;
    uint256 private constant tier2Duration = 30 minutes;
    uint256 private constant tier3Duration = 30 minutes;
    uint256 private constant tier4Duration = 30 minutes;
    uint256 private constant tier5Duration = 30 minutes;

    uint256 public constant TST = 0;
    uint256 nftPrice;

    string public goldNFTUrl;
    string public blackNFTUrl;
    uint256 public amount;

    constructor(
        string memory _goldNFTUrl,
        string memory _blackNFTUrl,
        uint256 _amount
    ) ERC1155("") Ownable(msg.sender) {
        _mint(msg.sender, TST, _amount * 10 ** 18, "");

        goldNFTUrl = _goldNFTUrl;
        blackNFTUrl = _blackNFTUrl;
        amount = _amount;

        tierDurations[1] = tier1Duration;
        tierDurations[2] = tier2Duration;
        tierDurations[3] = tier3Duration;
        tierDurations[4] = tier4Duration;
        tierDurations[5] = tier5Duration;
    }

    // owner can start tiers
    function startTier(uint256 _tier) external onlyOwner {
        require(_tier >= 1 && _tier <= 5, "Invalid tier");
        require(tierStartTimes[_tier] == 0, "Tier already started");
        tierStartTimes[_tier] = block.timestamp;
    }

    // 
    function registerUser(
        address _user,
        NFTType _nftType,
        uint256 _tier
    ) external {
        require(userNFTs[_user].tier == 0, "User already registered");
        require(_tier <= 2, "Invalid tier");
        userNFTs[_user] = Register(_nftType, _tier);
    }

    function purchaseNFT(NFTType _nftType) external payable {
        require(userNFTs[msg.sender].tier != 0, "User not registered");
        require(tierWhitelist[msg.sender] != 0, "User not whitelisted");
        uint256 currentTier = getCurrentStartedTier();
        require(
            currentTier == 1 || currentTier == 2,
            "Invalid tier for purchase"
        );
        uint256 price;
        uint256 purchaseLimit;
        if (currentTier == 1) {
            price = (_nftType == NFTType.Gold) ? 0.02 ether : 0.01 ether;
            purchaseLimit = 5;
            require(
                getTotalNFTsPurchased(msg.sender) < 5,
                "Purchase limit reached in Tier 1"
            );
            tier1NFTCount[msg.sender]++;
        } else if (currentTier == 2) {
            price = (_nftType == NFTType.Gold) ? 0.02 ether : 0.01 ether;
            purchaseLimit = 3;
            require(
                getTotalNFTsPurchased(msg.sender) >= 5 &&
                    getTotalNFTsPurchased(msg.sender) <= 8,
                "Purchase limit reached in Tier 2"
            );
            tier2NFTCount[msg.sender]++;
        } else {
            revert("Invalid tier");
        }
        require(msg.value >= price, "Insufficient funds");
        uint256 nftCount = getNFTCountByType(msg.sender, _nftType);

        require(nftCount <= purchaseLimit, "Purchase limit reached");
        _mint(msg.sender, uint256(_nftType), 1, "");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function whitelistUser(address _user) external onlyOwner {
        require(userNFTs[_user].tier <= 2, "Invalid tier");
        tierWhitelist[_user] = userNFTs[_user].tier;
    }

    function removeWhitelist(address _user) external onlyOwner {
        delete tierWhitelist[_user];
    }

    function setGoldNFTUrl(string calldata _goldNFTUrl) external onlyOwner {
        goldNFTUrl = _goldNFTUrl;
    }

    function setBlackNFTUrl(string calldata _blackNFTUrl) external onlyOwner {
        blackNFTUrl = _blackNFTUrl;
    }

    function setAmount(uint256 _amount) external onlyOwner {
        amount = _amount;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function redeem() external {
        uint256 currentTier = getCurrentStartedTier();
        require(currentTier > 0, "No tier started yet");
        require(
            currentTier == 3 || currentTier == 4 || currentTier == 5,
            "Invalid tier for purchase"
        );
        Register memory userNFT = userNFTs[msg.sender];
        uint256 totalTST = 0;
        if (userNFT.nftType == NFTType.Gold) {
            totalTST = 100;
        } else if (userNFT.nftType == NFTType.Black) {
            totalTST = 50;
        } else {
            revert("Invalid NFT type");
        }

        uint256 tier3Tokens = (totalTST * 50) / 100;
        uint256 tier4Tokens = (totalTST * 10) / 100;
        uint256 tier5Tokens = (totalTST * 40) / 100;
        uint256 currentTierTokens = 0;

        for (uint256 i = 3; i <= currentTier; i++) {
            if (i == 3) {
                currentTierTokens += tier3Tokens;
            } else if (i == 4) {
                currentTierTokens += tier4Tokens;
            } else if (i == 5) {
                currentTierTokens += tier5Tokens;
            }
        }
        _mint(msg.sender, TST, currentTierTokens, "");
    }

    function getCurrentStartedTier() internal view returns (uint256) {
        uint256 currentTier = 0;
        for (uint256 i = 1; i <= 5; i++) {
            if (tierStartTimes[i] != 0) {
                currentTier = i;
            }
        }
        return currentTier;
    }

    function getNFTCountByType(
        address _user,
        NFTType _nftType
    ) internal view returns (uint256) {
        if (_nftType == NFTType.Gold) {
            return tier1NFTCount[_user];
        } else if (_nftType == NFTType.Black) {
            return tier2NFTCount[_user];
        } else {
            revert("Invalid NFT type");
        }
    }

    function getTotalNFTsPurchased(
        address _user
    ) internal view returns (uint256) {
        return tier1NFTCount[_user] + tier2NFTCount[_user];
    }
}
