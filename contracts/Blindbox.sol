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

contract NewMetaBox is ERC721, ERC721URIStorage, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct BatchGroup {
        uint256 batchId;
        uint256 quantity;
        uint256 stock;
        bool isReveal;
    }

    mapping(uint256 => BatchGroup) batchGroups;

    uint256 public batchCount;
    event SoldOut(uint256 indexed soldQuantity, uint256 soldOutTimeStamp);

    uint256 public totalBoxes;
    bool public isReveal;
    string public baseURI;
    uint256 public boxPrice;
    bool public isSalesActive;
    uint256 private _initialIndex;
    string public baseExtension = ".json";

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 immutable s_callbackGasLimit = 100000;
    uint16 immutable s_requestConfirmations = 3;
    uint32 immutable s_numWords = 1;
    uint256 public s_requestId;
    uint256[] public s_randomWords;

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
        require(msg.value >= boxPrice * 1 ether, "Insufficient balance!");
        _;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function addNewBoxes(uint256 balance) public onlyOwner {
        batchGroups[batchCount] = BatchGroup(
            batchCount + 1,
            balance,
            balance,
            false
        );
        totalBoxes += balance;
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
        if (_initialIndex == 0) {
            s_requestId = COORDINATOR.requestRandomWords(
                s_keyHash,
                s_subscriptionId,
                s_requestConfirmations,
                s_callbackGasLimit,
                s_numWords
            );
            setStartingIndex();
        }
        batchGroups[batchNumber - 1].isReveal = true;
    }

    function getBatchIdentifier(uint256 tokenId)
        internal
        view
        onlyOwner
        returns (uint256)
    {
        for (uint256 i = 0; i < batchCount; i++) {
            if (tokenId <= batchGroups[i].quantity) {
                return batchGroups[i].batchId;
                break;
            }
        }
    }

    function purchaseBlindBox(address _to) public payable isQualified {
        require(_tokenIdCounter.current() < totalBoxes, "Sales ended");
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        if (newTokenId == totalBoxes) {
            emit SoldOut(totalBoxes, block.timestamp);
        }
        batchGroups[batchCount - 1].stock -= 1;
        _safeMint(_to, newTokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
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
        string memory currentBaseURI = _baseURI();
        string memory seqId;
        uint256 batchId = getBatchIdentifier(tokenId);
        if (batchGroups[batchId - 1].isReveal == false) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, "-1", baseExtension)
                    )
                    : "";
        } else {
            seqId = Strings.toString(
                (tokenId + _initialIndex) % batchGroups[batchId - 1].quantity
            );
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(currentBaseURI, seqId, baseExtension)
                    )
                    : "";
        }
    }

    function setStartingIndex() public onlyOwner {
        require(_initialIndex == 0, "Starting index is already set");

        _initialIndex = s_requestId % totalBoxes;

        if (_initialIndex == 0) {
            _initialIndex = _initialIndex.add(1);
        }
        isReveal == true;
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords)
        internal
        override
    {
        s_randomWords = randomWords;
    }
}
