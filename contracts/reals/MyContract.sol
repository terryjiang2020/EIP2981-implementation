//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ERC20Token {
    string public name;
    mapping(address => uint256) public balances;

    function mint() public {
        balances[tx.origin] ++;
    }
}

contract MyContract is ERC721, Ownable {
    // mapping(address => uint256) public balances;
    // address payable wallet;
    // address public token;

    // event Purchase (
    //     address _buyer,
    //     uint256 _amount
    // );

    // constructor(address payable _wallet, address _token) {
    //     wallet = _wallet;
    //     token = _token;
    // }

    // fallback() external payable {
    //     buyToken();
    // }

    // function buyToken() public payable {
    //     // // Buy a token
    //     // balances[msg.sender] += 1;

    //     // Mint a token
    //     ERC20Token _token = ERC20Token(address(token));
    //     _token.mint();

    //     // Send ether to the wallet
    //     wallet.transfer(msg.value);
    //     emit Purchase(msg.sender, 1);
    // }

    // NFT contract starts
    // https://www.youtube.com/watch?v=8WPzUbJyoNg

    uint256 public mintPrice = 0.05 ether;
    uint256 public totalSupply;
    uint256 public maxSupply;
    bool public isMintEnabled;
    mapping(address => uint256) public mintedWallets;

    constructor() payable ERC721('Simple Mint', 'SIMPLEMINT') {
        // 375 NFT for maximum
        maxSupply = 375; 
    }

    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        // Set the price dynamically
        mintPrice = mintPrice_;
    }

    function mint() external payable {
        // Prevent user mint any NFT before it starts
        require(isMintEnabled, 'minting not enabled');
        // Prevent user mint more NFTs than allowed
        require(mintedWallets[msg.sender] < 20, 'exceeds max per wallet');
        // Prevent user from minting with wrong price
        require(msg.value == mintPrice, 'wrong value');
        // Prevent user mint more NFTs than total supply
        require(maxSupply > totalSupply, 'sold out');

        mintedWallets[msg.sender]++;

        totalSupply++;

        uint256 tokenId = totalSupply;

        _safeMint(msg.sender, tokenId);
    }

    /// @notice Mint several tokens at once
    function mintBatch(uint256 number) external payable {
        // Prevent user mint any NFT before it starts
        require(isMintEnabled, 'minting not enabled');
        // Prevent user mint more NFTs than allowed
        require(mintedWallets[msg.sender] + number < 20, 'exceeds max per wallet');
        // Prevent user from minting with wrong price
        require(msg.value == mintPrice * number, 'wrong value');
        // Prevent user mint more NFTs than total supply
        require(maxSupply > totalSupply, 'sold out');

        for (uint256 i; i < number; i++) {
            mintedWallets[msg.sender]++;

            totalSupply++;

            uint256 tokenId = totalSupply;

            _safeMint(msg.sender, tokenId);
        }

    }


}