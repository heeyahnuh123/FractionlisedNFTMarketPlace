// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract FractionalNFTMarketplace is ReentrancyGuard {
    struct FractionalNFT {
        uint NFTId;
        IERC721 nft;
        uint tokenId;
        uint totalFractions;
        uint fractionsAvailable;
        uint pricePerFraction;
        uint totalValue;
        address payable owner;
        bool listed;
        mapping(address => uint) fractions;
    }

    mapping(uint => FractionalNFT) public fractionalNFTs;
    uint public fractionalNFTCount;
    uint public platformFee;

    event Fractionalized(
        uint NFTId,
        address indexed nft,
        uint tokenId,
        uint totalFractions,
        uint pricePerFraction,
        address indexed owner
    );

    event FractionsPurchased(
        uint NFTId,
        uint fractionsAmount,
        address indexed buyer
    );

    event FractionsTransferred(
        uint NFTId,
        uint fractionsAmount,
        address indexed from,
        address indexed to
    );

    modifier onlyOwner(uint _NFTId) {
        require(fractionalNFTs[_NFTId].owner == msg.sender, "Not the owner");
        _;
    }

    constructor(uint _platformFee) {
        platformFee = _platformFee;
    }

    function fractionalizeNFT(
        IERC721 _nft,
        uint _tokenId,
        uint _totalFractions,
        uint _pricePerFraction
    ) external nonReentrant {
        require(
            _totalFractions > 0,
            "Total fractions must be greater than zero"
        );
        require(
            _pricePerFraction > 0,
            "Price per fraction must be greater than zero"
        );

        fractionalNFTCount++;
        fractionalNFTs[fractionalNFTCount].NFTId = fractionalNFTCount;
        fractionalNFTs[fractionalNFTCount].nft = _nft;
        fractionalNFTs[fractionalNFTCount].tokenId = _tokenId;
        fractionalNFTs[fractionalNFTCount].totalFractions = _totalFractions;
        fractionalNFTs[fractionalNFTCount].fractionsAvailable = _totalFractions;
        fractionalNFTs[fractionalNFTCount].pricePerFraction = _pricePerFraction;
        fractionalNFTs[fractionalNFTCount].totalValue =
            _totalFractions *
            _pricePerFraction;
        fractionalNFTs[fractionalNFTCount].owner = payable(msg.sender);
        fractionalNFTs[fractionalNFTCount].listed = true;

        emit Fractionalized(
            fractionalNFTCount,
            address(_nft),
            _tokenId,
            _totalFractions,
            _pricePerFraction,
            msg.sender
        );
    }

    function purchaseFractions(
        uint _NFTId,
        uint _fractionsAmount
    ) external payable nonReentrant {
        FractionalNFT storage fractionalNFT = fractionalNFTs[_NFTId];
        require(
            _NFTId > 0 && _NFTId <= fractionalNFTCount,
            "NFT doesn't exist"
        );
        require(fractionalNFT.listed, "NFT not listed for fractionalization");
        require(
            _fractionsAmount > 0 &&
                _fractionsAmount <= fractionalNFT.fractionsAvailable,
            "Invalid fractions amount"
        );
        uint _totalPrice = _fractionsAmount * fractionalNFT.pricePerFraction;
        uint platformAmount = (_totalPrice * platformFee) / 1000;
        uint sellerAmount = _totalPrice - platformAmount;

        require(
            msg.value >= _totalPrice,
            "Not enough Ether to cover fraction cost"
        );

        fractionalNFT.owner.transfer(sellerAmount);
        payable(address(this)).transfer(platformAmount);
        fractionalNFT.fractionsAvailable -= _fractionsAmount;
        fractionalNFT.fractions[msg.sender] += _fractionsAmount;

        emit FractionsPurchased(_NFTId, _fractionsAmount, msg.sender);
    }

    function transferFractions(
        uint _NFTId,
        uint _fractionsAmount,
        address _to
    ) external nonReentrant {
        FractionalNFT storage fractionalNFT = fractionalNFTs[_NFTId];
        require(_NFTId > 0, "NFT doesn't exist");
        require(
            fractionalNFT.fractions[msg.sender] >= _fractionsAmount,
            "Not enough fractions to transfer"
        );

        fractionalNFT.fractions[msg.sender] -= _fractionsAmount;
        fractionalNFT.fractions[_to] += _fractionsAmount;

        emit FractionsTransferred(_NFTId, _fractionsAmount, msg.sender, _to);
    }
}
