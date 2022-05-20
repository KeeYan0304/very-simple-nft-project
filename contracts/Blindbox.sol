// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MetaBlindBox is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct BatchGroup {
        uint256 batchId;
        uint256 quantity;
        uint256 stock;
        uint256 currentTotalCount;
        bool isReveal;
        string baseURI;
    }

    mapping(uint256 => BatchGroup) batchGroups;

    uint256 public batchCount;
    event SoldOut(uint256 indexed soldQuantity, uint256 soldOutTimeStamp);

    uint256 public totalBoxes;
    string public notRevealURI;
    uint256 public boxPrice = 0.001 ether;
    bool public isSalesActive;
    uint256 private _initialIndex;
    string public baseExtension = ".json";
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 immutable s_callbackGasLimit = 100000;
    uint16 immutable s_requestConfirmations = 3;
    uint32 immutable s_numWords = 1;
    uint256 private s_requestId;

    address s_owner;

    Counters.Counter private _tokenIdCounter;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        string memory _name,
        string memory _symbol
    ) VRFConsumerBaseV2(vrfCoordinator) ERC721(_name, _symbol) {
        batchCount = 0;
        _tokenIdCounter.increment(); //starts with 1
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    modifier isQualified() {
        require(isSalesActive == true, "No ongoing sales");
        require(msg.sender != s_owner, "Owner cannot purchase");
        require(msg.value >= boxPrice, "Insufficient balance!");
        _;
    }

    function setRevealedURI(string memory _newBaseURI) public onlyOwner {
        batchGroups[batchCount - 1].baseURI = _newBaseURI;
    }

    function setNotRevealURI(string memory uri) public onlyOwner {
        notRevealURI = uri;
    }

    function addNewBoxes(uint256 balance) public onlyOwner {
        totalBoxes = totalBoxes.add(balance);
        BatchGroup memory batchGroup = BatchGroup(
            batchCount + 1,
            balance,
            balance,
            totalBoxes,
            false,
            ""
        );
        batchGroups[batchCount] = batchGroup;
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

    function revealBlindBox(uint256 batchNumber) public payable onlyOwner {
        require(batchGroups[batchNumber - 1].quantity != 0, "Batch not found");
        require(
            batchGroups[batchNumber - 1].stock == 0,
            "Blind box not sold out yet"
        );
        uint _startIndex;
        if (_initialIndex == 0) {
            s_requestId = COORDINATOR.requestRandomWords(
                s_keyHash,
                s_subscriptionId,
                s_requestConfirmations,
                s_callbackGasLimit,
                s_numWords
            );
        }
        _startIndex = s_requestId % totalBoxes;

        if (_startIndex == 0) {
            _startIndex = _startIndex.add(1);
        }
        _initialIndex = _startIndex;
        batchGroups[batchNumber - 1].isReveal = true;
    }

    function getBatchIdentifier(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < batchCount; i++) {
            if (i == 0) {
                if (tokenId <= batchGroups[i].currentTotalCount) { 
                    return batchGroups[i].batchId;
                }
            } else {
                if (tokenId >= batchGroups[i-1].currentTotalCount && tokenId <= batchGroups[i].currentTotalCount) {
                    return batchGroups[i].batchId;
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
        batchGroups[batchCount - 1].stock = batchGroups[batchCount - 1]
            .stock
            .sub(1);
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
        if (batchGroups[batchId - 1].isReveal == false) {
            return
                bytes(notRevealURI).length > 0
                    ? string(
                        abi.encodePacked(notRevealURI, "hidden", baseExtension)
                    )
                    : "";
        } else {
            string memory currentBaseURI = batchGroups[batchId - 1].baseURI;
            seqId = Strings.toString(
                ((tokenId + _initialIndex) %
                    batchGroups[batchId - 1].quantity) + 1
            );
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, seqId, baseExtension)
                    )
                    : "";
        }
    }

    function fulfillRandomWords(uint256, uint256[] memory) internal override {}

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