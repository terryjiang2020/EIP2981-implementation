//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
// import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../IERC2981Royalties.sol';

contract ERC20Token {
    string public name;
    mapping(address => uint256) public balances;

    function mint() public {
        balances[tx.origin] ++;
    }
}

// contract MyContract is ERC721, Ownable {
contract MyContract is ERC721Enumerable, Ownable, IERC2981Royalties {

    // NFT contract starts
    // https://www.youtube.com/watch?v=8WPzUbJyoNg

    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    RoyaltyInfo private _royalties;

    uint256 public mintPrice = 0.05 ether;
    uint256 public maxSupply;
    bool public isMintEnabled;
    mapping(address => uint256) public mintedWallets;
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    string[] private tokenURIArray;

    constructor() payable ERC721('Senkusha Ash Supe', 'SENKUSHAASHSUPE') {
        // 375 NFT for maximum
        maxSupply = 375; 
        baseTokenURI = "";
        tokenURIArray = [
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg",
            "https://gateway.pinata.cloud/ipfs/QmV6T3pSLoGXUWUky23bkrvaaqw92PneQQTZvN8BsArToW",
            "https://gateway.pinata.cloud/ipfs/QmXpMWXTnpuvgZxAMwkW2AFd2co878RaW6BURUfSJVAghg"
        ];
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

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public {
        baseTokenURI = _baseTokenURI;
    }

    function mintHandler() internal {

        mintedWallets[msg.sender]++;

        // totalSupply++;

        uint256 tokenId = totalSupply() + 1;

        string memory tokenURINeo = tokenURIArray[totalSupply()];

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, tokenURINeo);

        return;
    }

    function mint() external payable {
        // Prevent user mint any NFT before it starts
        require(isMintEnabled, 'minting not enabled');
        // Prevent user mint more NFTs than allowed
        require(mintedWallets[msg.sender] < 20, 'exceeds max per wallet');
        // Prevent user from minting with wrong price
        require(msg.value == mintPrice, 'wrong value');
        // Prevent user mint more NFTs than total supply
        require(maxSupply > totalSupply() + 1, 'sold out');

        mintHandler();
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
        require(maxSupply > totalSupply() + 1, 'sold out');

        for (uint256 i; i < number; i++) {
            mintHandler();
        }

    }

    // ERC721URIStorage.sol
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev This function in a real contract should be protected with a onlyOwner (or equivalent) modifier
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        _setRoyalties(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

}