import axios from 'axios';
import { useState } from 'react';
import FormData from 'form-data';

function ImgUploader() {
    const [post, setPost] = useState({ IpfsHash: "" });
    const [image, setImage] = useState(null);
    const [isUploaded, setIsUploaded] = useState(false);
    const onImageChange = (event) => {
        if (event.target.files && event.target.files[0]) {
            setImage(URL.createObjectURL(event.target.files[0]));
            setIsUploaded(true);

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
                setPost(response.data);
            }).catch(function (error) {
                alert(error + event.target.files[0]);
            });
        }
    }

    return (
        <div>
            <input type="file" onChange={onImageChange} className="filetype" />
            <img src={isUploaded ? image : 'img/placeholder.png'} width={250} height={250}></img>
            <img src={`https://gateway.pinata.cloud/ipfs/${post.IpfsHash}`}></img>
            {/* <button onClick={pinFileToIPFS}>Click to upload image</button> */}
        </div>
    )
}

export default ImgUploader;

