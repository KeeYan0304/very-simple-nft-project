// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OptBlindBox is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    mapping(uint256 => uint256) batchIds;
    mapping(uint256 => uint256) quantity;
    mapping(uint256 => uint256) stock;
    mapping(uint256 => uint256) currentTotalCount;
    mapping(uint256 => bool) isReveal;
    mapping(uint256 => string) baseURI;

    uint256 public batchCount;
    event SoldOut(uint256 indexed soldQuantity, uint256 soldOutTimeStamp);

    uint256 public totalBoxes;
    string public notRevealURI;
    uint256 public boxPrice = 0.001 ether;
    bool public isSalesActive;
    uint256 private _initialIndex;
    string public baseExtension = ".json";

    address s_owner;

    uint randNonce = 0;

    Counters.Counter private _tokenIdCounter;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        batchCount = 0;
        _tokenIdCounter.increment(); //starts with 1
        s_owner = msg.sender;
    }

    modifier isQualified() {
        require(isSalesActive == true, "No ongoing sales");
        require(msg.sender != s_owner, "Owner cannot purchase");
        require(msg.value >= boxPrice, "Insufficient balance!");
        _;
    }

    function setRevealedURI(string memory _newBaseURI) public onlyOwner {
        baseURI[batchCount - 1] = _newBaseURI;
    }

    function setNotRevealURI(string memory uri) public onlyOwner {
        notRevealURI = uri;
    }

    function addNewBoxes(uint256 balance) public onlyOwner {
        totalBoxes = totalBoxes.add(balance);
        batchIds[batchCount] = batchCount + 1;
        quantity[batchCount] = balance;
        stock[batchCount] = balance;
        currentTotalCount[batchCount] = totalBoxes;
        isReveal[batchCount] = false;
        batchCount++;
    }

    function setBoxPrice(uint256 price) public onlyOwner {
        boxPrice = price;
    }

    function setSalesActive(bool isActive) public onlyOwner {
        if (isActive == true) {
            require(boxPrice > 0, "Box price is not set");
            isSalesActive = isActive;
        } else {
            isSalesActive = isActive;
        }
    }

    function checkTotalBoxes() public view returns (uint256) {
        return totalBoxes;
    }

    function randMod() internal returns(uint)
    {
        randNonce = randNonce.add(1); 
        return uint(keccak256(abi.encodePacked(block.number,
                                          msg.sender,
                                          randNonce))).mod(10).add(1);
    }

    function revealBlindBox(uint256 batchNumber) public onlyOwner {
        require(quantity[batchNumber - 1] != 0, "Batch not found");
        require(
            stock[batchNumber - 1] == 0,
            "Blind box not sold out yet"
        );
        uint _startIndex;
        if (_initialIndex == 0) {
            _startIndex = randMod();
        }
        _initialIndex = _startIndex;
        isReveal[batchNumber - 1] = true;
    }

    function getBatchIdentifier(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < batchCount; i++) {
            if (i == 0) {
                if (tokenId <= currentTotalCount[i]) { 
                    return batchIds[i];
                }
            } else {
                if (tokenId >= currentTotalCount[i-1] && tokenId <= currentTotalCount[i]) {
                    return batchIds[i];
                }
            }
        }
        return 0;
    }

    function purchaseBlindBox() public payable isQualified {
        require(_tokenIdCounter.current() <= totalBoxes, "Sales ended");
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        if (newTokenId == totalBoxes) {
            emit SoldOut(totalBoxes, block.timestamp);
        }
        stock[batchCount - 1] = stock[batchCount - 1].sub(1);
        _safeMint(msg.sender, newTokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory seqId;
        uint256 batchId = getBatchIdentifier(tokenId);
        require(batchId != 0, "token id not found");
        if (isReveal[batchId - 1] == false) {
            return
                bytes(notRevealURI).length > 0
                    ? string(
                        abi.encodePacked(notRevealURI, "hidden", baseExtension)
                    )
                    : "";
        } else {
            string memory currentBaseURI = baseURI[batchId - 1];
            seqId = Strings.toString(
                ((tokenId + _initialIndex) %
                    quantity[batchId - 1]) + 1
            );
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, seqId, baseExtension)
                    )
                    : "";
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}