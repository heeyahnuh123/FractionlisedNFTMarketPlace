// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    // Declaration of state variables
    address payable public immutable feeAccount;
    uint public immutable feePercent;
    uint public itemCount;

    struct Item {
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }

    event Offered(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );

    event Bought(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    mapping(uint => Item) public items;

    constructor(uint _feePercent) {
        // Initialize the ReentrancyGuard
        //ReentrancyGuard.initialize();

        // Initialize the Ownable contract with the contract owner
        Ownable.transferOwnership(msg.sender);

        // Setting the fee account
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function makeItem(
        IERC721 _nft,
        uint _tokenId,
        uint _price
    ) external nonReentrant {
        require(_price > 0, "Price must be greater than zero");

        // Increasing the item count
        itemCount++;

        // Transferring the NFT to the smart contract
        _nft.transferFrom(msg.sender, address(this), _tokenId);

        // Adding a new item to the mapping
        items[itemCount] = Item(
            itemCount,
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );

        // Emitting an event
        emit Offered(itemCount, address(_nft), _tokenId, _price, msg.sender);
    }

    function purchaseItem(uint _itemId) external payable nonReentrant {
        uint _totalPrice = getTotalPrice(_itemId);
        Item storage item = items[_itemId];

        require(_itemId > 0 && _itemId <= itemCount, "Item doesn't exist");
        require(
            msg.value >= _totalPrice,
            "Not enough ether to cover item cost and market fee"
        );
        require(!item.sold, "Item already sold");

        // Pay the seller and transaction fee
        item.seller.transfer(item.price);
        feeAccount.transfer(_totalPrice - item.price);

        // Update the item to reflect that it has been sold
        item.sold = true;

        // Transfer the NFT to the buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);

        // Emitting a bought event
        emit Bought(
            _itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );
    }

    function getTotalPrice(uint _itemId) public view returns (uint) {
        return ((items[_itemId].price * (100 + feePercent)) / 100);
    }

    // Function to allow the platform to withdraw accumulated fees
    function withdrawPlatformFees() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw");
        uint platformFee = (address(this).balance * feePercent) / 1000;
        payable(owner()).transfer(platformFee);
    }

    // Function to check the contract's balance
    function contractBalance() external view returns (uint) {
        return address(this).balance;
    }
}
