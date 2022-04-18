// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FreeGuy is ERC721, ERC721URIStorage, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(string => uint8) private existingURIs;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    uint256 public _salePrice = 1; // 0.050 ETH

    constructor() ERC721("FreeGuy", "FYR") {}

    // function _baseURI() internal pure override returns (string memory) {
    //     return "ipfs://";
    // }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        existingURIs[uri] = 1;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
        _balances[msg.sender] -= 1;
    }

    function getPrice() public view returns (uint256) {
        return _salePrice;
    }

    function setPrice(uint256 newPrice) public {
        _salePrice = newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    function payToMint(address recipient, string memory metadataURI)
        public
        payable
        returns (uint256)
    {
        require(existingURIs[metadataURI] != 1, "NFT already minted!");
        require(msg.value == _salePrice * 1 ether, "Need to pay up!");

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        existingURIs[metadataURI] = 1;
        _mint(recipient, newItemId);
        _owners[newItemId] = msg.sender;
        _setTokenURI(newItemId, metadataURI);
        _balances[msg.sender] += 1;
        return newItemId;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    // function burnNFT(uint256 tokenId) public virtual {
    //     _burn(tokenId);
    // }

    function count() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // function changeAttributes(
    //     uint256 newStat,
    //     uint256 tokenId,
    //     string memory newTokenURI
    // ) public {
    //     require(
    //         _isApprovedOrOwner(_msgSender(), tokenId),
    //         "ERC721: caller is not owner nor approved"
    //     );
    //     tokenIdToStat[tokenId] = newStats;
    //     _setTokenURI(tokenId, newTokenURI);
    // }
}
