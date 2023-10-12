// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract NFT is ERC721, Ownable {
    address marketplaceAddress;

    constructor(address _marketplaceAddress) ERC721("Iyanuoluwa", "IY") {
        marketplaceAddress = _marketplaceAddress;
    }

    // Mint NFT and assign it to the sender
    function mintNFT(
        address to,
        uint256 tokenId,
        string memory tokenURI
    ) public onlyOwner {
        _mint(to, tokenId);
        //_setTokenURI(tokenId, tokenURI);
    }

    // Transfer NFT to the marketplace
    function transferNFT(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        IERC721(marketplaceAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    // Transfer NFT back to the owner
    function transferNFTBack(uint256 tokenId) public onlyOwner {
        require(
            owner() == msg.sender,
            "You are not the owner of the marketplace"
        );
        IERC721(marketplaceAddress).transferFrom(
            address(this),
            ownerOf(tokenId),
            tokenId
        );
    }
}
