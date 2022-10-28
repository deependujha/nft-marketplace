// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint listPrice = 0.01 ether;

    constructor() ERC721("EagleNFT", "ENFT") {
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    mapping(uint256 => ListedToken) idToListedToken;

    function updateListPrice(uint256 _price) public {
        require(msg.sender == owner, "Only owner can update the list-price");
        listPrice = _price;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken()
        public
        view
        returns (ListedToken memory)
    {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }

    function getListedForTokenId(uint256 tokenId)
        public
        view
        returns (ListedToken memory)
    {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    function createToken(string memory _tokenURI, uint256 _price)
        public
        payable
        returns (uint)
    {
        require(msg.value >= listPrice, "Send enough ethers to list");
        require(_price > 0, "Make sure price is greater than 0 ethers");

        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, _tokenURI);
        createListedToken(currentTokenId, _price);
        return currentTokenId;
    }

    function createListedToken(uint256 _tokenId, uint256 _price) private {
        idToListedToken[_tokenId] = ListedToken(
            _tokenId,
            payable(address(this)),
            payable(msg.sender),
            _price,
            true
        );
        _transfer(msg.sender, address(this), _tokenId);
    }

    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint256 nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        for (uint i = 0; i < nftCount; i++) {
            uint currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return tokens;
    }

    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        // Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].seller == msg.sender ||
                idToListedToken[i + 1].owner == msg.sender
            ) {
                itemCount++;
            }
        }

        // Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].seller == msg.sender ||
                idToListedToken[i + 1].owner == msg.sender
            ) {
                ListedToken storage currentItem = idToListedToken[i + 1];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 _tokenId) public payable {
        uint price = idToListedToken[_tokenId].price;
        require(
            msg.value >= price,
            "Please submit the asking price for the NFT in order to purchase"
        );

        address seller = idToListedToken[_tokenId].seller;
        idToListedToken[_tokenId].currentlyListed = true;
        idToListedToken[_tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        _transfer(address(this), msg.sender, _tokenId);
        approve(address(this), _tokenId);
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }
}
