// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./NFT.sol";

contract Market is ReentrancyGuard {

    address payable public immutable feeAccount;
    uint public immutable feePercent;
    uint public itemCount;

    enum ItemStatus { Available, Sold, Canceled }

    struct Item {
        uint itemId;
        address nftAddress;
        uint tokenId;
        uint price;
        address payable seller;
        ItemStatus status;
    }

    mapping(uint => Item) public items;

    event Offered(
        uint indexed itemId,
        address indexed nft,
        uint indexed tokenId,
        uint price,
        address seller
    );

    event Bought(
        uint indexed itemId,
        address indexed nft,
        uint indexed tokenId,
        uint price,
        address seller,
        address buyer
    );

    event Canceled(
        uint indexed itemId,
        address indexed nft,
        uint indexed tokenId,
        address seller
    );

    constructor(uint _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    function makeItem(address _nftAddress, uint _tokenId, uint _price) 
        external nonReentrant 
    {
        require(_price > 0, "Price must be greater than 0");

        IERC721 nft = IERC721(_nftAddress);
        nft.transferFrom(msg.sender, address(this), _tokenId);

        itemCount++;
        items[itemCount] = Item({
            itemId: itemCount,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price,
            seller: payable(msg.sender),
            status: ItemStatus.Available
        });

        emit Offered(itemCount, _nftAddress, _tokenId, _price, msg.sender);
    }

    function purchaseItem(uint _itemId) external payable nonReentrant isAvailable(_itemId) {
        Item storage item = items[_itemId];
        uint totalPrice = getTotalPrice(_itemId);
        require(msg.value >= totalPrice, "Insufficient funds");

        NFT nft = NFT(item.nftAddress);

        uint royalty = (item.price * nft.getRoyaltyPercentage()) / 100;
        address creator = nft.getCreator(item.tokenId);
        uint sellerProceeds = item.price - royalty;
        uint marketFee = totalPrice - item.price;

        payable(creator).transfer(royalty);
        item.seller.transfer(sellerProceeds);
        feeAccount.transfer(marketFee);

        IERC721(item.nftAddress).transferFrom(address(this), msg.sender, item.tokenId);

        item.status = ItemStatus.Sold;

        emit Bought(_itemId, item.nftAddress, item.tokenId, item.price, item.seller, msg.sender);
    }

    function cancelItem(uint _itemId) external nonReentrant isAvailable(_itemId) {
        Item storage item = items[_itemId];
        require(msg.sender == item.seller, "Only seller can cancel");

        item.status = ItemStatus.Canceled;

        IERC721(item.nftAddress).transferFrom(address(this), item.seller, item.tokenId);

        emit Canceled(_itemId, item.nftAddress, item.tokenId, msg.sender);
    }

    function getTotalPrice(uint _itemId) public view returns(uint) {
        return (items[_itemId].price * (100 + feePercent)) / 100;
    }

    modifier isAvailable(uint _itemId) {
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        require(items[_itemId].status == ItemStatus.Available, "Item not available");
        _;
    }
}
