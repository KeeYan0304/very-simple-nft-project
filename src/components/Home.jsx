import WalletBalance from './WalletBalance';
import { useEffect, useState } from 'react';

import { ethers } from 'ethers';
import FreeGuy from '../artifacts/contracts/MyNFT.sol/FreeGuy.json';

import axios from 'axios';
import FormData from 'form-data';

import TextField from "@material-ui/core/TextField";

const contractAddress = '0x0697436901d4E0eEB0f0E3D4EEEabAf4B5Dc34F3';

const provider = new ethers.providers.Web3Provider(window.ethereum);

// get the end user
const signer = provider.getSigner();

// get the smart contract
const contract = new ethers.Contract(contractAddress, FreeGuy.abi, signer);

let mintPrice = 1; //global var

function Home() {
    const [totalMinted, setTotalMinted] = useState(0);
    const [totalTokenIds, setTotalTokenIds] = useState([]);
    const [salePrice, setSalePrice] = useState(0);
    useEffect(() => {
        getCount();
        checkMintPrice();
    }, []);

    const getCount = async () => {
        const count = await contract.count();
        console.log(parseInt(count));
        setTotalMinted(parseInt(count));
    };

    const updateSalesPrice = async () => {
        console.log('updateprice: ' + salePrice);
        contract.setPrice(salePrice);
    }

    const checkMintPrice = async () => {
        setSalePrice(parseInt(await contract.getPrice()));
        mintPrice = parseInt(await contract.getPrice());
        console.log('checkMintPrice: ' + mintPrice);
    };

    const address = async () => {
        return await provider.getSigner().getAddress();
    }

    return (
        <div>
            <div>
                {/* <h2>Wallet Address: {address}</h2> */}
            </div>
            <div style={{ marginTop: "20px" }}>
                <WalletBalance />
            </div>
            <div style={{ marginTop: "50px" }}>
                <div>
                    <TextField
                        value={salePrice}
                        label="Enter mint price"
                        onChange={(e) => {
                            setSalePrice(e.target.value);
                            mintPrice = e.target.value;
                        }}
                    />
                    <button onClick={updateSalesPrice}>Edit Mint Price</button>
                </div>
                <h5>Total assets: {totalMinted}</h5>
                {Array(totalMinted + 1)
                    .fill(0)
                    .map((_, i) => (
                        <div key={i}>
                            {/* {i == totalMinted &&
                                <h2>
                                    <ImgUploader />
                                </h2>
                            }
                            {i != totalMinted && */}
                            <h2>
                                <NFTImage tokenId={i} getCount={getCount} />
                            </h2>
                            {/* } */}
                        </div>
                    ))}
            </div>
        </div>
    );
}

function ImgUploader() {
    const [post, setPost] = useState();
    const [image, setImage] = useState(null);
    const [isUploaded, setIsUploaded] = useState(false);
    const onNewImage = (event) => {
        if (event.target.files && event.target.files[0]) {
            setImage(URL.createObjectURL(event.target.files[0]));

            const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;
            let data = new FormData();
            data.append('file', event.target.files[0], event.target.files[0].name);
            return axios.post(url,
                data,
                {
                    headers: {
                        'Content-Type': `multipart/form-data; boundary= ${data._boundary}`,
                        'pinata_api_key': '256479555901346e3039',
                        'pinata_secret_api_key': '24d4c8a307b070fd734ca1e7ed1ff3f791442cc686be27404dd8915965df8879'
                    }
                }
            ).then(function (response) {
                setPost(response.data.IpfsHash);
                setIsUploaded(true);
            }).catch(function (error) {
                alert(error + event.target.files[0]);
            });
        }
    }

    return (
        <div style={{ marginTop: "20px" }}>
            {!isUploaded &&
                <input type="file" onChange={onNewImage} className="filetype" />
            }
            {/* <img src={isUploaded ? image : 'img/placeholder.png'} width={250} height={250}></img> */}
            {isUploaded &&
                <h2>
                    {/* <img src={isUploaded ? `https://gateway.pinata.cloud/ipfs/${post}` : 'img/placeholder.png'} width={250} height={250}></img> */}
                    <img src={isUploaded ? image : 'img/placeholder.png'} width={250} height={250}></img>
                    <IPFSImg ipfsHash={post} />
                </h2>
            }
            {/* <button onClick={pinFileToIPFS}>Click to upload image</button> */}
        </div>
    )
}

function NFTImage({ tokenId, getCount }) {
    const contentId = 'QmPk5u6ajpJfEdHjXCLwzujDGseZHDnuJuo3zF7Do5nmuY';
    // const metadataURI = `${contentId}/${tokenId}.json`;
    // let metadataURI = "";
    // const imageURI = `https://gateway.pinata.cloud/ipfs/${contentId}/${tokenId}.png`;
    const [imageURI, setImageURI] = useState();
    const [metadataURI, setMetadataURI] = useState();

    const checkIPFS = async () => {
        const uri = await contract.tokenURI(tokenId);
        const url = `https://api.pinata.cloud/data/pinList?status=pinned`;
        return axios.get(url,
            {
                headers: {
                    'pinata_api_key': '256479555901346e3039',
                    'pinata_secret_api_key': '24d4c8a307b070fd734ca1e7ed1ff3f791442cc686be27404dd8915965df8879'
                }
            }
        ).then(function (response) {
            var i;
            for (i = 0; i < response.data.count; i++) {
                if (uri.includes(response.data.rows[i].ipfs_pin_hash)) {
                    setImageURI(`https://gateway.pinata.cloud/ipfs/${response.data.rows[i].ipfs_pin_hash}`);
                    setMetadataURI(`ipfs://${response.data.rows[i].ipfs_pin_hash}/${tokenId}.json`);
                }

            }
        }).catch(function (error) {
            alert(error);
        });
    }


    const [isMinted, setIsMinted] = useState(false);
    const [owner, setOwner] = useState();
    useEffect(() => {
        getMintedStatus();
    }, [isMinted]);

    const getMintedStatus = async () => {
        const uri = await contract.tokenURI(tokenId);
        const result = await contract.isContentOwned(uri);
        console.log('uri: ' + uri);
        setIsMinted(result);
        checkIPFS();
    };

    const mintToken = async () => {
        const connection = contract.connect(signer);

        const addr = connection.address;
        const ownAddr = await signer.getAddress();
        // console.log("minttokenuri: " + metadataURI)
        console.log("mintTokenPrice: " + mintPrice)
        const result = await contract.payToMint(ownAddr, metadataURI, {
            value: ethers.utils.parseEther('' + mintPrice),
        });
        // const result = await contract.safeMint(ownAddr, metadataURI);

        await result.wait();
        getMintedStatus();
        getCount();
    };

    const burnToken = async () => {
        // const approve = await contract.burnNFT(tokenId);
        const approve = await contract.burn(tokenId);
        await approve.wait();
    };

    async function getURI() {
        const uri = await contract.tokenURI(tokenId);
        alert(uri);
    }

    const getOwnerAddr = async () => {
        console.log("owner: " + tokenId);
        const owner = await contract.ownerOf(tokenId);
        setOwner(owner);
        console.log("owner: " + owner + tokenId);
    };

    const getTokenIds = async () => {
        const checkCount = await contract.count();
        const totalCounts = parseInt(checkCount);
        const ownAddr = await signer.getAddress();
        for (var i = 0; i < totalCounts; i++) {
            const owner = await contract.ownerOf(i);
            if (owner == ownAddr) {
                const updatedTokenArr = [...totalTokenIds, owner];
                setTotalTokenIds(updatedTokenArr);
            }
            console.log("owner: " + owner);
        }
    }

    const updateURI = async () => {
        const result = await contract.updateMetaURI(tokenId, metadataURI);
        await result.wait();
    }

    const [post, setPost] = useState();
    const [image, setImage] = useState(null);
    const [isUploaded, setIsUploaded] = useState(false);

    const onNewImage = (event) => {
        if (event.target.files && event.target.files[0]) {
            setImage(URL.createObjectURL(event.target.files[0]));
            const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;
            let data = new FormData();
            data.append('file', event.target.files[0], event.target.files[0].name);
            return axios.post(url,
                data,
                {
                    headers: {
                        'Content-Type': `multipart/form-data; boundary= ${data._boundary}`,
                        'pinata_api_key': '256479555901346e3039',
                        'pinata_secret_api_key': '24d4c8a307b070fd734ca1e7ed1ff3f791442cc686be27404dd8915965df8879'
                    }
                }
            ).then(function (response) {
                setPost(response.data.IpfsHash);
                setImageURI(`https://gateway.pinata.cloud/ipfs/${response.data.IpfsHash}`)
                setMetadataURI(`ipfs://${response.data.IpfsHash}/${tokenId}.json`);
                setIsUploaded(true);
            }).catch(function (error) {
                alert(error + event.target.files[0]);
            });
        }
    }

    const onImageChange = (event) => {
        if (event.target.files && event.target.files[0]) {
            setImage(URL.createObjectURL(event.target.files[0]));
            const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;
            let data = new FormData();
            data.append('file', event.target.files[0], event.target.files[0].name);
            return axios.post(url,
                data,
                {
                    headers: {
                        'Content-Type': `multipart/form-data; boundary= ${data._boundary}`,
                        'pinata_api_key': '256479555901346e3039',
                        'pinata_secret_api_key': '24d4c8a307b070fd734ca1e7ed1ff3f791442cc686be27404dd8915965df8879'
                    }
                }
            ).then(function (response) {
                setPost(response.data.IpfsHash);
                setImageURI(`https://gateway.pinata.cloud/ipfs/${response.data.IpfsHash}`)
                setMetadataURI(`ipfs://${response.data.IpfsHash}/${tokenId}.json`);
                updateURI();
                // setIsUploaded(true);
            }).catch(function (error) {
                alert(error + event.target.files[0]);
            });
        }
    }

    return (
        <div>
            <div>
                {/* <img src={isMinted ? imageURI : 'img/placeholder.png'}></img> */}
                {!isMinted ? (
                    <div>
                        {!isUploaded ? (
                            <div>
                                <input type="file" onChange={onNewImage} className="filetype" />
                                <img src={isUploaded ? `https://gateway.pinata.cloud/ipfs/${post}` : 'img/placeholder.png'} width={250} height={250}></img>
                            </div>
                        ) : (
                            <div>
                                <img src={isUploaded ? `https://gateway.pinata.cloud/ipfs/${post}` : 'img/placeholder.png'} width={250} height={250}></img>
                                <button onClick={mintToken}>
                                    Mint
                                </button>
                            </div>

                        )}
                    </div>
                ) : (
                    <div>
                        <img src={isMinted ? imageURI : 'img/placeholder.png'} width={250} height={250}></img>
                        <h5>Image URL: {imageURI}</h5>
                        <h5>Token ID: {tokenId}</h5>
                        <button onClick={getURI}>
                            Taken! Show URI
                        </button>
                        {/* <label htmlFor="filePicker" style={{ background: "grey", padding: "5px 10px" }}>
                            Change Image
                        </label>
                        <input id="filePicker" style={{ visibility: "hidden" }} type={"file"} onChange={onImageChange} /> */}
                        <div>
                            <button onClick={burnToken}>
                                Burn Token
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}

export default Home;

