// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//main minter contract for eranauts
//contract till 18-11-2022 11:40:00 (added reward function and added event for buy item).

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERAMinter is ERC1155, Ownable {
    uint256 public currentTokenId;

    //reward attributes
    uint256 public rewardTokenMaxSupply = 50;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    mapping(uint256 => uint256) public copiesPerTokenId;

    // mapping(uint256 => uint256) public priceOfToken;

    //manually changing nft/token uri
    mapping(uint256 => string) public _tokenURIs;

    function _setTokenUri(uint256 tokenId, string memory tokenURI)
        public
        onlyOwner
    {
        _tokenURIs[tokenId] = tokenURI;
    }

    //manually changing nft/token uri  ends...................

    address payable public _owner;

    //log message (like consoling any message)
    event Log(string message);

    constructor()
        ERC1155(
            "https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/{id}.json"
        )
    {
        name = "Eranauts";
        symbol = "ERA";
        _owner = payable(msg.sender);
    }

    //minting nfts in batch by _mintBatch()

    //domenstration parameters bellow:
    //ids =>        [21,22,23]
    //amounts =>    [40,1,300]
    //metadata(s):  ["https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/0.json","https://              bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/0.json","https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/0.json"]

    //single mint variation
    function mintSingleByID(uint256 tokenId, uint256 amount)
        public
    // uint256 tknPrice
    {
        _mint(msg.sender, tokenId, amount, "");
        copiesPerTokenId[currentTokenId] += amount;

        //setting token price along with minting it
        // priceOfToken[tokenId] = tknPrice;
        currentTokenId++;
    }

    //by onlyOwner
    function mintReward() public onlyOwner {
        // this mint function mints the reward token of id "0" with amount 50 as declared Initially
        _mint(_owner, 0, rewardTokenMaxSupply, "reward tokens(ERA tokens)");
        copiesPerTokenId[0] = rewardTokenMaxSupply;
    }

    //to change existing or add new URI for whole collection of NFTs function
    function newSetURI(string memory _uri, uint256 tokenId) public onlyOwner {
        _tokenURIs[tokenId] = _uri;
        _setURI(_uri);
        emit Log(_uri);
    }

    // checking if token is NFT or FT
    function checkIsNFT(uint256 tokenId) public view returns (bool) {
        if (copiesPerTokenId[tokenId] == 1) {
            return true;
        } else {
            return false;
        }
    }

    //set token uri function
    // function uri(uint256 tokenID) public view override returns (string memory) {
    //     return (
    //         string(
    //             //Eranauts metadata link:  https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/4.json
    //             //pokemon metadata link:  https://bafybeiho2j43vulwhnjmfyvjafohl5prvcx24hr2sqvz7wliynnodmovru.ipfs.dweb.link/100.json
    //             abi.encodePacked(
    //                 "https://bafybeiho2j43vulwhnjmfyvjafohl5prvcx24hr2sqvz7wliynnodmovru.ipfs.dweb.link/",
    //                 Strings.toString(tokenID),
    //                 ".json"
    //             )
    //         )
    //     );
    // }

    // token/nft burning function (workin in progress)
    function Burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner returns (bool) {
        _burn(account, id, amount);
        return true;
    }
}
