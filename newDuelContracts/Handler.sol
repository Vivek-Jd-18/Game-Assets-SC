// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//contract till 23-11-2022(Wednesday) 15:52:00 (modified buy, sell and reward function according
//                                           to new contract totally, contract optimized by reducing contract size ).

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERAMinter.sol";

contract ERAHandler is ERAMinter {
    mapping(uint8 => uint8) public priceOfToken;

    uint8 public boughtID = 0;

    //manually changing nft/token uri ends...................

    struct buyStruct {
        uint8 tokenId;
        uint8 tokenAmount;
        uint8 price;
        bool sold;
        address payable tokenOwner;
        address payable tokenSeller;
    }

    //log message (when Item is sold)
    event ItemSold(
        uint8 indexed tokenId,
        uint8 indexed tokenAmount,
        address indexed tokenSeller,
        address newTokenOwner,
        uint8 price,
        bool sold
    );

    //log message (when user is Rewarded)
    event rewardSent(
        uint8 indexed tokenId,
        uint8 indexed tokenAmount,
        address indexed tokenSeller,
        address rewardReceiver,
        bool rewarded
    );

    mapping(uint8 => buyStruct) public buyHandler;
    IERC1155 private myToken;

    // address payable ParentAddress;

    constructor(IERC1155 _token) {
        myToken = _token;
        _owner = payable(msg.sender);
    }

    //setting price of particular token.
    function setPriceOfToken(uint8 valInETH, uint8 tokenId) public onlyOwner {
        priceOfToken[tokenId] = valInETH;
    }

    function buy(
        address payable from,
        address payable to,
        uint8 tokenId,
        uint8 amount
    ) public payable returns (bool) {
        string
            memory s1 = "ethers you are trying to send is less please send enough ethers";

        require(msg.value >= (priceOfToken[tokenId] * (10**18)) * amount, s1);

        IERC1155(myToken).safeTransferFrom(
            _owner,
            address(this),
            tokenId,
            amount,
            ""
        );
        // please paste this contract's address in "from" parameter.
        myToken.safeTransferFrom(
            from,
            to,
            tokenId,
            IERC1155(myToken).balanceOf(address(this), tokenId),
            ""
        );

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

        // emitting an event after token is sold
        emit ItemSold(
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
        uint8 tokenId,
        uint8 amount
    ) public payable {
        uint8 price = priceOfToken[tokenId];
        require(amount > 0, "amount to sold is less");
        require(
            amount <= IERC1155(myToken).balanceOf(msg.sender, tokenId),
            "sorry you don't have the token you have entered or don't have  enough tokens amount as you have entered!"
        );

        payable(msg.sender).transfer(price * (10**18) * amount);
        myToken.safeTransferFrom(
            msg.sender,
            to,
            tokenId,
            amount,
            "sold the NFT successfully"
        );
    }

    function withdrawAllAmount() public onlyOwner returns (bool) {
        _owner.transfer(address(this).balance);
        return true;
    }

    //STAKING work
    uint8 public totalRewardSupply;
    mapping(uint8 => address) public tokenOwner;
    mapping(uint8 => mapping(address => uint256)) public tokenStakedAtTime;
    mapping(address => mapping(uint8 => uint8)) public tokenAmountStaked;
    uint16 public rewardTokenIdCount = 1000;
    uint8 public rewardRate = 1; // has to be changed !

    function stack(uint8 tokenId, uint8 tokenAmount) external {
        tokenAmountStaked[msg.sender][tokenId] = tokenAmount;
        myToken.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            tokenAmount,
            ""
        );
        tokenOwner[tokenId] = msg.sender;
        tokenStakedAtTime[tokenId][msg.sender] = block.timestamp;
    }

    function unstack(uint8 tokenId) external {
        uint8 tokenAmount = tokenAmountStaked[msg.sender][tokenId];
        require(tokenOwner[tokenId] == msg.sender, "you are not a owner");

        //note : currently below we are giving an NFT as a reward to the user.
        _mint(msg.sender, rewardTokenIdCount, 1, " ");
        totalRewardSupply++;
        rewardTokenIdCount++;
        myToken.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            tokenAmount,
            ""
        );
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

    // reward function for completing in-game tasks ==> with onlyOwner
    function gameReward(
        address from,
        address to,
        uint8 tokenId,
        uint8 amount
    ) public onlyOwner returns (bool) {
        require(tokenId == 0, "sending the wrong token as a reward");

        //buy logic for reward
        IERC1155(myToken).safeTransferFrom(
            _owner,
            address(this),
            tokenId,
            amount,
            ""
        );
        // please paste this contract's address in "from" parameter.
        myToken.safeTransferFrom(from, to, tokenId, amount, "");
        emit rewardSent(tokenId, amount, _owner, to, true);
        return true;
    }

    function customBalance(address add, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return IERC1155(myToken).balanceOf(add, tokenId);
    }
}
