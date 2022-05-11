// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MetaBlindBox is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    VRFConsumerBaseV2
{
    uint256 public constant firstReleaseDate = 1655697600; //mid June
    uint256 public constant secReleaseDate = 1656302400; // 1 week after 1st batch release
    uint256 public constant thirdReleaseDate = 1656648000; // early July

    uint256 private _sold_first_batch_count;
    uint256 private _sold_sec_batch_count;
    uint256 private _sold_third_batch_count;

    uint256 public _first_batch_reveal_date;
    uint256 public _sec_batch_reveal_date;
    uint256 public _third_batch_reveal_date;

    uint256 public constant MAX_FIRST_BATCH = 1111;
    uint256 public constant MAX_SEC_BATCH = 2222;
    uint256 public constant MAX_THIRD_BATCH = 4444;
    uint256 public constant MAX_TOKENS_SUPPLY = 7777;

    string public baseURI;
    string public baseExtension = ".json";

    string public constant NFT_PROVENANCE_HASH =
        "59b3ce2eab81c2d7bbd4184b82e51edce17b28e8243a3a247c7ae15aca288b4f";

    uint256[] private _randomTokenNumber;

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    constructor(
        uint64 subscriptionId,
        string memory _name,
        string memory _initBaseURI,
        string memory _symbol
    ) ERC721(_name, _symbol) VRFConsumerBaseV2(vrfCoordinator) {
        setBaseURI(_initBaseURI);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        createNewSubscription();
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
        setInitialIndex();
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomId() public onlyOwner returns (uint256) {
        // Will revert if subscription is not set and funded.
        return
            s_requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    uint256 private _initialIndex;

    function setInitialIndex() public payable onlyOwner {
        require(_initialIndex == 0, "Starting index is already set");

        _initialIndex = s_requestId % MAX_TOKENS_SUPPLY;

        if (_initialIndex == 0) {
            _initialIndex = _initialIndex.add(1);
        }
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
        if (tokenId <= MAX_FIRST_BATCH) {
            if (
                _first_batch_reveal_date != 0 &&
                block.timestamp >= _first_batch_reveal_date
            ) {
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                Strings.toString(tokenId),
                                baseExtension
                            )
                        )
                        : "";
            } else {
                if (block.timestamp >= firstReleaseDate) {
                    seqId = Strings.toString(
                        (tokenId + _initialIndex) % MAX_FIRST_BATCH
                    );
                    return
                        bytes(currentBaseURI).length > 0
                            ? string(
                                abi.encodePacked(
                                    currentBaseURI,
                                    seqId,
                                    baseExtension
                                )
                            )
                            : "";
                }
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                "-1",
                                baseExtension
                            )
                        )
                        : "";
            }
        } else if (tokenId > MAX_FIRST_BATCH && tokenId < MAX_SEC_BATCH) {
            if (
                _sec_batch_reveal_date != 0 &&
                block.timestamp >= _sec_batch_reveal_date
            ) {
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                Strings.toString(tokenId),
                                baseExtension
                            )
                        )
                        : "";
            } else {
                if (block.timestamp >= secReleaseDate) {
                    seqId = Strings.toString(
                        (tokenId + _initialIndex) %
                            (MAX_FIRST_BATCH + MAX_SEC_BATCH)
                    );
                    return
                        bytes(currentBaseURI).length > 0
                            ? string(
                                abi.encodePacked(
                                    currentBaseURI,
                                    seqId,
                                    baseExtension
                                )
                            )
                            : "";
                }
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                "-1",
                                baseExtension
                            )
                        )
                        : "";
            }
        } else {
            if (
                _third_batch_reveal_date != 0 &&
                block.timestamp >= _third_batch_reveal_date
            ) {
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                Strings.toString(tokenId),
                                baseExtension
                            )
                        )
                        : "";
            } else {
                if (block.timestamp >= thirdReleaseDate) {
                    seqId = Strings.toString(
                        (tokenId + _initialIndex) % MAX_TOKENS_SUPPLY
                    );
                    return
                        bytes(currentBaseURI).length > 0
                            ? string(
                                abi.encodePacked(
                                    currentBaseURI,
                                    seqId,
                                    baseExtension
                                )
                            )
                            : "";
                }
                return
                    bytes(currentBaseURI).length > 0
                        ? string(
                            abi.encodePacked(
                                currentBaseURI,
                                "-1",
                                baseExtension
                            )
                        )
                        : "";
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function payToMint(address _to) public payable {
        uint256 availableSupply;
        if (block.timestamp >= firstReleaseDate) {
            availableSupply = MAX_FIRST_BATCH;
        }
        if (block.timestamp >= secReleaseDate) {
            availableSupply = MAX_FIRST_BATCH + MAX_SEC_BATCH;
        }
        if (block.timestamp >= thirdReleaseDate) {
            availableSupply = MAX_FIRST_BATCH + MAX_SEC_BATCH + MAX_THIRD_BATCH;
        }
        require(_tokenIdCounter.current() < availableSupply, "Sales ended");
        // uint256 randomIndex = (requestRandomId() % availableSupply) + 1;

        // uint256 newTokenId = _randomTokenNumber[randomIndex];

        // _randomTokenNumber[randomIndex] = _randomTokenNumber[
        //     _randomTokenNumber.length - 1
        // ];

        // _randomTokenNumber.pop();
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, newTokenId);

        if (newTokenId <= MAX_FIRST_BATCH) {
            _sold_first_batch_count += 1;
            if (_sold_first_batch_count == MAX_FIRST_BATCH) {
                _first_batch_reveal_date = block.timestamp + 3 days;
            }
        } else if (newTokenId > MAX_FIRST_BATCH && newTokenId < MAX_SEC_BATCH) {
            _sold_sec_batch_count += 1;
            if (_sold_sec_batch_count == MAX_SEC_BATCH) {
                _sec_batch_reveal_date = block.timestamp + 3 days;
            }
        } else {
            _sold_third_batch_count += 1;
            if (_sold_third_batch_count == MAX_THIRD_BATCH) {
                _third_batch_reveal_date = block.timestamp + 3 days;
            }
        }
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}
