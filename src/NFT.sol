// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NFTLocked is ERC20, ERC1155, Ownable {
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
    mapping(address => uint256[]) public tierWhitelist;
    mapping(address => uint256) public tier1NFTCount;
    mapping(address => uint256) public tier2NFTCount;
    mapping(uint256 => uint256) public tierStartTimes;

    event UserRegistered(address indexed user, NFTType nftType, uint256[] tier);

    uint256 private constant tier1Duration = 30 minutes;
    uint256 private constant tier2Duration = 30 minutes;
    uint256 private constant tier3Duration = 30 minutes;
    uint256 private constant tier4Duration = 30 minutes;
    uint256 private constant tier5Duration = 30 minutes;

    string public goldNFTUrl;
    string public blackNFTUrl;

    constructor(
        string memory _goldNFTUrl,
        string memory _blackNFTUrl
    ) ERC20("TestToken", "TST") ERC1155("") Ownable(msg.sender) {
        goldNFTUrl = _goldNFTUrl;
        blackNFTUrl = _blackNFTUrl;

        tierDurations[1] = tier1Duration;
        tierDurations[2] = tier2Duration;
        tierDurations[3] = tier3Duration;
        tierDurations[4] = tier4Duration;
        tierDurations[5] = tier5Duration;
    }

    function initialize(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount * 10 ** 18);
    }

    // owner can start tiers
    function startTier(uint256 _tier) external onlyOwner {
        require(_tier >= 1 && _tier <= 5, "Invalid tier");
        require(tierStartTimes[_tier] == 0, "Tier already started");
        tierStartTimes[_tier] = block.timestamp;
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

    function isUserRegistered(address _user) public view returns (bool) {
        return userNFTs[_user].tier.length > 0;
    }

    function purchaseNFT(NFTType _nftType, uint256 _amount) external payable {
        require(userNFTs[msg.sender].tier.length > 0, "User not registered");
        require(tierWhitelist[msg.sender].length > 0, "User not whitelisted");

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
            tier1NFTCount[msg.sender]++;
        } else {
            price = (_nftType == NFTType.Gold) ? 0.02 ether : 0.01 ether;
            purchaseLimit = 3;
            tier2NFTCount[msg.sender]++;
        }

        uint256 totalPrice = price * _amount;

        require(msg.value >= totalPrice, "Insufficient funds");
        uint256 nftCount = getNFTCountByType(msg.sender, _nftType);
        require(nftCount <= purchaseLimit, "Purchase limit reached");

        _mint(msg.sender, uint256(_nftType), _amount, "");

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function whitelistUser(address _user) external onlyOwner {
        require(userNFTs[_user].tier.length <= 2, "Invalid tier");
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

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function redeem() external {
        uint256 currentTier = getCurrentStartedTier();
        require(currentTier > 0, "No tier started yet");
        require(
            currentTier == 3 || currentTier == 4 || currentTier == 5,
            "Invalid tier for redemption"
        );
        Register memory userNFT = userNFTs[msg.sender];

        uint256 totalTST = 0;
        if (userNFT.nftType == NFTType.Gold) {
            totalTST = 100;
        } else {
            totalTST = 50;
        }

        uint256 totalNFTs = getTotalNFTsPurchased(msg.sender);
        uint256 tier3Tokens = (totalTST * 50) / 100;
        uint256 tier4Tokens = (totalTST * 10) / 100;
        uint256 tier5Tokens = (totalTST * 40) / 100;
        uint256 currentTierTokens = 0;

        if (currentTier == 3) {
            currentTierTokens += tier3Tokens;
        } else if (currentTier == 4) {
            if (tierStartTimes[3] >= tierStartTimes[4]) {
                currentTierTokens += tier3Tokens + tier4Tokens;
            } else {
                currentTierTokens += tier4Tokens;
            }
        } else if (currentTier == 5) {
            if (tierStartTimes[4] >= tierStartTimes[5]) {
                currentTierTokens += tier3Tokens + tier4Tokens + tier5Tokens;
            } else {
                currentTierTokens += tier5Tokens;
            }
        }

        uint256 totalTokens = (totalNFTs * totalTST) / 100;
        uint256 redeemableTokens = (totalTokens * currentTierTokens) / 100;

        require(
            balanceOf(address(this)) >= redeemableTokens,
            "Insufficient TST balance in contract"
        );
        transfer(msg.sender, redeemableTokens);
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
