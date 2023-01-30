// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/// @title NFT Marketplace Project
/// @author Muhammad Farooq(Blockchain Developer)
///BNB address = 0xe8adc554a1b33505117ab7b2a488322f9a06eedf
contract myERC721 is ERC721URIStorage, Ownable{
    IERC20 BNB;


    struct userData{
        uint256 totalNFTs;
        uint256[] myNFTIDs;
        uint256 nftSold;
        uint256[] soldNFTIDs;
    }

    struct nftData{
        uint256 id;
        address owner;
        address royaltyAddress;
        uint256 price;
        uint256 royaltyPercentage;
        uint256 royaltyAmount;
        string uri;
        bool onList;
    }

    mapping(address => userData) public usersData;
    mapping(uint256 => nftData) public nftsData;
    mapping(uint256 => nftData) public listedNFTs;


    uint256 public mintTax = 16000000000000000;
    address payable taxReceiver1= payable(0xdD870fA1b7C4700F2BD7f44238821C26f7392148);
    address payable taxReceiver2 = payable(0x583031D1113aD414F02576BD6afaBfb302140225);
    uint256 listedNFTCount;

    /// @notice To initialize contract
    /// @dev Just give token address which will be used to interact on marketplace
    constructor(IERC20 _BNBAddress)
    ERC721("NFTContract", "NFTC")
    {
        BNB = _BNBAddress;
    }

    /// @notice To mint your own nft
    /// @dev Just give nft uri and id you want to mint
    function mint(
        string memory _tokenURI,
        uint256 _tokenID)
        public
    {
        uint256 taxAmount1;
        uint256 taxAmount2;
        require(BNB.balanceOf(msg.sender) >= mintTax, "Not enough Tax Amount 50BUSD");
        _mint(msg.sender ,_tokenID);
        _setTokenURI(_tokenID, _tokenURI );
        usersData[msg.sender].totalNFTs +=1;
        usersData[msg.sender].myNFTIDs.push(_tokenID);
        nftsData[_tokenID] = nftData(_tokenID, msg.sender, msg.sender, 0, 0, 0, _tokenURI, false);
        taxAmount1 = (70 * mintTax) / 100;
        taxAmount2 = (30 * mintTax) / 100;
        BNB.transferFrom(msg.sender, taxReceiver1, taxAmount1);
        BNB.transferFrom(msg.sender, taxReceiver2, taxAmount2);
    }

    /// @notice To sell nft
    /// @dev Just give nft id you wanna sell, its price and royalty percentage if artist

    function sellNFT(uint256 _id, uint256 _price, uint256 _royaltyPercentage) public payable
    {
        uint256 taxPrice;
        uint256 taxAmount1;
        uint256 taxAmount2;
        uint256 royaltyAmount;
        require(msg.sender == ownerOf(_id), "Not NFT Owner");
        require(_royaltyPercentage <= 25, " 0 < Royalty <= 25");
        listedNFTs[_id].id = _id;
        listedNFTs[_id].owner = msg.sender;
        listedNFTs[_id].royaltyAddress = nftsData[_id].royaltyAddress;
        listedNFTs[_id].price = _price;
        listedNFTs[_id].uri = tokenURI(_id);

        if(msg.sender == nftsData[_id].royaltyAddress)
        {
            listedNFTs[_id].royaltyPercentage = _royaltyPercentage;
            nftsData[_id].royaltyPercentage = _royaltyPercentage;
            royaltyAmount = (_royaltyPercentage * _price)/100;
            listedNFTs[_id].royaltyAmount = royaltyAmount;
            nftsData[_id].royaltyAmount = royaltyAmount;
        }
        else
        {
            listedNFTs[_id].royaltyPercentage = nftsData[_id].royaltyPercentage;
        }

        listedNFTs[_id].onList = true;
        nftsData[_id].price = _price;
        nftsData[_id].onList = true;
        usersData[msg.sender].nftSold +=1;
        usersData[msg.sender].soldNFTIDs.push(_id);
        taxPrice = (2 * _price)/ 100;
        taxAmount1 = (70 * taxPrice)/100;
        taxAmount2 = (30 * taxPrice)/100;
        BNB.transferFrom(msg.sender, taxReceiver1, taxAmount1);
        BNB.transferFrom(msg.sender, taxReceiver2, taxAmount2);
        listedNFTCount+=1;
    }

    /// @notice To buy nft
    /// @dev Just give nft id you wanna buy, if on sale

    function buyNFT(uint256 _id) public payable
    {
        uint256 taxPrice;
        uint256 taxAmount1;
        uint256 taxAmount2;
        
        require(BNB.balanceOf(msg.sender) >= nftsData[_id].price, "Not enough balance");
        require(nftsData[_id].onList == true, "Not for Sale");
        require(msg.sender != nftsData[_id].owner, "Already Owner");


        listedNFTs[_id].owner = msg.sender;
        listedNFTs[_id].onList = false;
        nftsData[_id].onList = false;

        taxPrice = (2 * nftsData[_id].price)/ 100;
        taxAmount1 = (70 * taxPrice)/100;
        taxAmount2 = (30 * taxPrice)/100;
        BNB.transferFrom(msg.sender, payable(nftsData[_id].owner), nftsData[_id].price);
        BNB.transferFrom(msg.sender, payable(taxReceiver1), taxAmount1);
        BNB.transferFrom(msg.sender, payable(taxReceiver2), taxAmount2);
        BNB.transferFrom(msg.sender, payable(nftsData[_id].royaltyAddress), nftsData[_id].royaltyAmount);

        usersData[msg.sender].totalNFTs +=1;
        usersData[msg.sender].myNFTIDs.push(_id);
        listedNFTCount -= 1;
    }

    /// @notice To set per nft minting tax
    /// @dev only owner can call it
    function setMintTaxPerNFT(
        uint256 _newTax)
        public 
        onlyOwner
    {
        mintTax = _newTax;
    }

    /// @notice To stop selling your nft
    /// @dev Just give nft id you wanna stop selling.
    function stopSellingNFT(uint256 _id) public
    {
        require(msg.sender == nftsData[_id].owner, "Not Owner");
        listedNFTs[_id].onList = false;
        nftsData[_id].onList = false;
    }

    function approve(address spender, uint256 amount) public override onlyOwner {
        IERC20 tokenA = BNB;
        tokenA.approve(spender, amount);
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

}
