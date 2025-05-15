// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFT.sol";

contract NFTFactory is Ownable {
    uint256 public mintingFee;
    
    struct CollectionInfo {
        address collection;
        string name;
        string symbol;
    }

    CollectionInfo[] public collections;

    event CollectionCreated(address indexed creator, address indexed collection, string name, string symbol);
    event FeesWithdrawn(uint256 amount);

    constructor(uint256 _mintingFee) {
        mintingFee = _mintingFee;
    }

    function createCollection(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 royaltyPercentage
    ) external payable returns (address) {
        require(msg.value >= mintingFee, "Fee not paid");
        require(bytes(name).length > 0 && bytes(name).length <= 32, "Invalid name");
        require(bytes(symbol).length > 0 && bytes(symbol).length <= 10, "Invalid symbol");
        require(maxSupply > 0 && maxSupply <= 1e9, "Invalid supply");
        require(royaltyPercentage <= 100, "Royalty too high");

        NFT collection = new NFT(name, symbol, maxSupply, msg.sender, royaltyPercentage);

        collections.push(CollectionInfo({
            collection: address(collection),
            name: name,
            symbol: symbol
        }));

        emit CollectionCreated(msg.sender, address(collection), name, symbol);
        return address(collection);
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        payable(owner()).transfer(balance);
        emit FeesWithdrawn(balance);
    }

    function getAllCollections() external view returns (CollectionInfo[] memory) {
        return collections;
    }

    function getCollectionsCount() external view returns (uint256) {
        return collections.length;
    }
}
