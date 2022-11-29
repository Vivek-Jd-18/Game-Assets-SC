// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//contract till 16-11-2022 18:48:00 (added reward function and added event for buy item).

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERA is ERC1155, Ownable {
    uint256 public currentTokenId;
    mapping(address => mapping(uint256 => uint256)) soldFromOwner;

    //reward attributes
    uint256 public rewardTokenMaxSupply = 50;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    mapping(uint256 => uint256) public copiesPerTokenId;

    mapping(uint256 => mapping(address => address)) public newOwnerAfterBuy;

    mapping(uint256 => uint256) public itemsSoldByTokenId;

    mapping(uint256 => uint256) public priceOfToken;

    uint256 public boughtID = 0;

    //manually changing nft/token uri
    mapping(uint256 => string) public _tokenURIs;

    function _setTokenUri(uint256 tokenId, string memory tokenURI)
        public
        onlyOwner
    {
        _tokenURIs[tokenId] = tokenURI;
    }

    //manually changing nft/token uri  ends...................

    struct buyStruct {
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 price;
        bool sold;
        address payable tokenOwner;
        address payable tokenSeller;
    }

    //log message (when Item is sold)
    event ItemCreated(
        uint256 indexed tokenId,
        uint256 indexed tokenAmount,
        address indexed tokenSeller,
        address newTokenOwner,
        uint256 price,
        bool sold
    );

    //log message (when user is Rewarded)
    event rewardSent(
        uint256 indexed tokenId,
        uint256 indexed tokenAmount,
        address indexed tokenSeller,
        address rewardReceiver,
        bool rewarded
    );

    mapping(uint256 => buyStruct) public buyHandler;

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
    function BatchMint(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(msg.sender, ids, amounts, data);

        //domenstration parameters bellow:
        //ids =>        [21,22,23]
        //amounts =>    [40,1,300]
        //metadata(s):  ["https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/0.json","https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/0.json","https://bafybeidt754leppzcjpsd46sepygwzj4a525c5qinjgiabkltnbvoptu3y.ipfs.dweb.link/0.json"]
    }

    //single mint
    function mintSingle(uint256 amount) public {
        copiesPerTokenId[currentTokenId] += amount;
        uri(currentTokenId);
        _mint(msg.sender, currentTokenId, amount, "");
        currentTokenId++;
    }

    //single mint variation
    function mintSingleByID(
        uint256 tokenId,
        uint256 amount,
        uint256 tknPrice
    ) public {
        _mint(msg.sender, tokenId, amount, "");
        copiesPerTokenId[currentTokenId] += amount;

        //setting token price along with minting it
        priceOfToken[tokenId] = tknPrice;
        currentTokenId++;
    }

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

    //function to concatenate the string
    function concatenate(
        string memory a,
        bytes32 b,
        string memory c
    ) public pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b, " ", c));
    }

    //uint to bytes
    function uintToBytes(uint256 v) private pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint256(ret) / (2**8));
                ret |= bytes32(((v % 10) + 48) * 2**(8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function buy(
        address payable to,
        uint256 tokenId,
        uint256 amount
    ) public payable returns (bool) {
        string
            memory s1 = " 'ethers you are trying to send is either less please send";
        string memory s2 = " ether/ethers! '";
        uint256 tokenPrice = priceOfToken[tokenId];
        bytes32 FilteredTotalPrice = uintToBytes(tokenPrice);
        string memory valueError = concatenate(s1, FilteredTotalPrice, s2);
        require(
            msg.value >= (priceOfToken[tokenId] * (10**18)) * amount,
            valueError
        );
        _safeTransferFrom(_owner, to, tokenId, amount, " ");
        soldFromOwner[_owner][tokenId]++;
        itemsSoldByTokenId[tokenId] = amount;
        newOwnerAfterBuy[tokenId][to] = to;

        //storing all the details of this transaction in buy structure
        buyHandler[boughtID] = buyStruct(
            tokenId,
            amount,
            priceOfToken[tokenId],
            true,
            to,
            _owner
        );
        boughtID++;

        //emitting an event after token is sold
        emit ItemCreated(
            tokenId,
            amount,
            _owner,
            _owner,
            priceOfToken[tokenId],
            true
        );
        return true;
    }

    function sell(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public payable {
        uint256 price = priceOfToken[tokenId];
        require(amount > 0, "amount to be sold is less");
        require(
            amount <= balanceOf(msg.sender, tokenId),
            "sorry you don't have enough tokens amount as you have entered!"
        );
        payable(msg.sender).transfer(price * (10**18) * amount);
        _safeTransferFrom(
            msg.sender,
            to,
            tokenId,
            amount,
            "sold the NFT successfully"
        );
        newOwnerAfterBuy[tokenId][to] = to;
        itemsSoldByTokenId[tokenId] = amount;
    }

    // checking if token is NFT or FT
    function checkIsNFT(uint256 tokenId) public view returns (bool) {
        if (copiesPerTokenId[tokenId] == 1) {
            return true;
        } else {
            return false;
        }
    }

    function withdrawAllAmount() public onlyOwner returns (bool) {
        _owner.transfer(address(this).balance);
        return true;
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

    //STAKING work
    uint256 public totalRewardSupply;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => mapping(address => uint256)) public tokenStakedAtTime;
    mapping(address => mapping(uint256 => uint256)) public tokenAmountStaked;
    uint256 public rewardTokenIdCount = 1000;
    uint256 public rewardRate = 1; // has to be changed !

    function stack(uint256 tokenId, uint256 tokenAmount) external {
        tokenAmountStaked[msg.sender][tokenId] = tokenAmount;
        _safeTransferFrom(msg.sender, address(this), tokenId, tokenAmount, "");
        tokenOwner[tokenId] = msg.sender;
        tokenStakedAtTime[tokenId][msg.sender] = block.timestamp;
    }

    function calculateRewards(uint256 tokenId) public view returns (uint256) {
        uint256 timeElapsed = block.timestamp -
            tokenStakedAtTime[tokenId][msg.sender];
        return timeElapsed / 60;
    }

    function unstack(uint256 tokenId) external {
        uint256 tokenAmount = tokenAmountStaked[msg.sender][tokenId];
        require(tokenOwner[tokenId] == msg.sender, "you are not a owner");
        // _setTokenURI(tokenid, tokenURI);

        //note : currently below we are giving an NFT as a reward to the user.
        _mint(msg.sender, rewardTokenIdCount, calculateRewards(tokenId), " ");
        totalRewardSupply++;
        rewardTokenIdCount++;
        _safeTransferFrom(address(this), msg.sender, tokenId, tokenAmount, "");
        delete tokenOwner[tokenId];
        delete tokenStakedAtTime[tokenId][msg.sender];
    }

    //onReceive method to accept tokens
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // token/nft burning function (workin in progress)
    function Burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner returns (bool) {
        _burn(account, id, amount);
        return true;
    }

    //setting price of particular token.
    function setPriceOfToken(uint256 valInETH, uint256 tokenId)
        public
        onlyOwner
    {
        require(
            copiesPerTokenId[tokenId] >= 1,
            "Sorry this id doesn't have any tokens"
        );
        priceOfToken[tokenId] = valInETH;
    }

    // reward function for completing in-game tasks
    function gameReward(
        uint256 tokenId,
        address to,
        uint256 amount
    ) public onlyOwner returns (bool) {
        require(tokenId == 0, "sending the wrong token as a reward");
        _safeTransferFrom(_owner, to, tokenId, amount, "");
        emit rewardSent(tokenId, amount, _owner, to, true);
        return true;
    }
}
