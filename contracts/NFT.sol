// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    uint256 public immutable maxSupply;
    uint256 public immutable royaltyPercentage;

    Counters.Counter private _tokenIds;
    mapping(uint256 => address) private _creators;

    event TokenMinted(uint256 indexed tokenId, address indexed to, string uri);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _maxSupply,
        address creator_,
        uint256 _royaltyPercentage
    ) ERC721(name_, symbol_) Ownable(creator_) {
        require(_royaltyPercentage <= 100, "Royalty too high");
        maxSupply = _maxSupply;
        royaltyPercentage = _royaltyPercentage;
    }

    function mint(string memory _uri) external onlyOwner returns (uint256) {
        require(_tokenIds.current() < maxSupply, "Max supply reached");
        require(bytes(_uri).length > 0, "URI required");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _uri);
        _creators[newTokenId] = msg.sender;

        emit TokenMinted(newTokenId, msg.sender, _uri);
        return newTokenId;
    }

    function getCreator(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "Token not exist");
        return _creators[tokenId];
    }

    function totalMinted() external view returns (uint256) {
        return _tokenIds.current();
    }
}
