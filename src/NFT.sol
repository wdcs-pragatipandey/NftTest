// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../src/TST.sol";
contract NFTLocked is ERC1155, TestToken {
    // enum to choose nft type
    enum NFTType {
        Gold,
        Black,
        Both
    }

    // struct for register Users
    struct Register {
        NFTType nftType;
        uint256[] tier;
    }

    // mappings
    mapping(address => Register) public userNFTs;
    mapping(uint256 => uint256) public tierDurations;
    mapping(address => uint256) public whitelistCounter;
    mapping(address => mapping(uint256 => bool)) public tierWhitelist;
    mapping(address => uint256) public tier1NFTCount;
    mapping(address => uint256) public tier2NFTCount;
    mapping(uint256 => uint256) public tierStartTimes;
    mapping(address => bool) public isRegistered;
    mapping(uint256 => bool) public tierActiveStatus;

    event UserRegistered(address indexed user, NFTType nftType, uint256[] tier);

    uint256 private constant tier1Duration = 30 minutes;
    uint256 private constant tier2Duration = 30 minutes;
    uint256 private constant tier3Duration = 30 minutes;
    uint256 private constant tier4Duration = 30 minutes;
    uint256 private constant tier5Duration = 30 minutes;

    TestToken Token =
        TestToken(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));

    constructor() ERC1155("ipfs://CID/{id}.json") {
        tierDurations[1] = tier1Duration;
        tierDurations[2] = tier2Duration;
        tierDurations[3] = tier3Duration;
        tierDurations[4] = tier4Duration;
        tierDurations[5] = tier5Duration;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function startTier(uint256 _tier) external onlyOwner {
        require(_tier >= 1 && _tier <= 5, "Invalid tier");
        require(tierStartTimes[_tier] == 0, "Tier already started");
        tierStartTimes[_tier] = block.timestamp;
        tierActiveStatus[_tier] = true;
    }

    function endTier(uint256 tierId) public {
        require(tierActiveStatus[tierId], "Tier not active");
        tierActiveStatus[tierId] = false;
    }

    function registerUser(
        address _user,
        NFTType _nftType,
        uint256[] memory _tier
    ) external {
        require(userNFTs[_user].tier.length == 0, "User already registered");
        require(_tier.length <= 2, "Invalid tier");
        userNFTs[_user] = Register(_nftType, _tier);
        emit UserRegistered(_user, _nftType, _tier);
    }

    function whitelistUser(address _user) external {
        uint256[] memory userTiers = userNFTs[_user].tier;
        for (uint256 i = 0; i < userTiers.length; i++) {
            tierWhitelist[_user][userTiers[i]] = true;
            whitelistCounter[_user]++;
        }
    }

    function removeWhitelist(address _user) external onlyOwner {
        whitelistCounter[_user] = 0;
        for (uint256 i = 1; i <= 5; i++) {
            delete tierWhitelist[_user][i];
        }
    }

    function isUserRegistered(address _user) public view returns (bool) {
        return userNFTs[_user].tier.length > 0;
    }

    function purchaseNFT(NFTType _nftType, uint256 _amount) external payable {
        require(userNFTs[msg.sender].tier.length > 0, "User not registered");
        require(whitelistCounter[msg.sender] > 0, "User not whitelisted");
        uint256 currentTier = getCurrentStartedTier();
        require(
            currentTier == 1 || currentTier == 2,
            "Invalid tier for purchase"
        );
        require(currentTier > 0, "No tier started yet");
        require(tierActiveStatus[currentTier], "Tier not active");

        uint256 price;
        uint256 purchaseLimit;

        if (currentTier == 1) {
            price = (_nftType == NFTType.Gold) ? 0.02 ether : 0.01 ether;
            purchaseLimit = 5;
            tier1NFTCount[msg.sender] += _amount;
        } else {
            price = (_nftType == NFTType.Gold) ? 0.02 ether : 0.01 ether;
            purchaseLimit = 3;
            tier2NFTCount[msg.sender] += _amount;
        }

        uint256 totalPrice = price * _amount;

        require(msg.value >= totalPrice, "Insufficient funds");
        uint256 nftCount = getNFTCountByType(msg.sender, _nftType);
        require(nftCount + _amount <= purchaseLimit, "Purchase limit reached");

        _mint(msg.sender, uint256(_nftType), _amount, "");

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        // require(balance>0, "No fund to withdraw");
        payable(owner()).transfer(balance);
    }

    function redeem() external {
        uint256 currentTier = getCurrentStartedTier();
        require(
            currentTier >= 3 && currentTier <= 5,
            "Invalid tier for redemption"
        );
        Register memory userNFT = userNFTs[msg.sender];
        uint256 totalTST = (userNFT.nftType == NFTType.Gold) ? 100 : 50;

        uint256 totalNFTs = getTotalNFTsPurchased(msg.sender);
        uint256 tier3Tokens = (totalTST * 50) / 100;
        uint256 tier4Tokens = (totalTST * 10) / 100;
        uint256 tier5Tokens = (totalTST * 40) / 100;
        uint256 missedTierTokens = 0;

        if (
            currentTier >= 3 &&
            tierStartTimes[3] != 0 &&
            block.timestamp > (tierStartTimes[3] + tierDurations[3])
        ) {
            missedTierTokens += tier3Tokens;
        }

        if (
            currentTier >= 4 &&
            tierStartTimes[4] != 0 &&
            block.timestamp > (tierStartTimes[4] + tierDurations[4])
        ) {
            missedTierTokens += tier4Tokens;
        }

        uint256 currentTierTokens;
        if (currentTier == 3) {
            currentTierTokens = tier3Tokens;
        } else if (currentTier == 4) {
            currentTierTokens = tier4Tokens;
        } else if (currentTier == 5) {
            currentTierTokens = tier5Tokens;
        }

        currentTierTokens += missedTierTokens;

        uint256 totalTokens = (totalNFTs * totalTST) / 100;
        uint256 redeemableTokens = (totalTokens * currentTierTokens) / 100;

        require(
            balanceOf(address(this)) >= redeemableTokens,
            "Insufficient TST balance in owner's account"
        );
        transfer(msg.sender, redeemableTokens);
    }

    function getCurrentStartedTier() internal view returns (uint256) {
        uint256 currentTier = 0;
        for (uint256 i = 1; i <= 5; i++) {
            if (tierStartTimes[i] != 0 && tierActiveStatus[i]) {
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
        } else {
            return tier2NFTCount[_user];
        }
    }

    function getTotalNFTsPurchased(
        address _user
    ) internal view returns (uint256) {
        return tier1NFTCount[_user] + tier2NFTCount[_user];
    }
}
