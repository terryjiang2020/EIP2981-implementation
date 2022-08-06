//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract ERC5Token {
    string public name;
    mapping(address => uint256) public balances;
    function mint() public {
        balances[tx.origin] ++;
    }
}
// contract MyContract is ERC721, Ownable {
contract MyContract is ERC721Enumerable, Ownable {
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            int256 price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }
    // NFT contract starts
    // https://www.youtube.com/watch?v=8WPzUbJyoNg
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }
    RoyaltyInfo private _royalties;
    uint256 public mintPrice = 0.05 ether;
    uint256 public minMintPrice = 0.05 ether;
    uint256 public maxMintPrice = 0.05 ether;
    uint256 public ethPrice = 0;
    uint256 public unitRaise = 10500 / 375;
    uint256 public maxSupply;
    bool public isMintEnabled;
    mapping(address => uint256) public mintedWallets;
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    using ECDSA for bytes32;
    address private _systemAddress = 0xe45539fE76E31DF9D126f6Aa59B8d24267394524;
    mapping(string => bool) public _usedNonces;
    mapping(uint256 => bool) public _usedNftIds;
    // ERC721URIStorage.sol
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    constructor() payable ERC721('Senkusha Ash Supe', 'SENKUSHAASHSUPE') {
        // 375 NFT for maximum
        maxSupply = 375; 
        _setRoyalties(msg.sender, 350);
        baseTokenURI = "";
        resetMintPrice();
    }
    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
        resetMintPrice();
    }
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        // Set the price dynamically
        mintPrice = mintPrice_;
    }
    function _setEthPrice(uint256 ethPrice_) internal {
        ethPrice = ethPrice_;
    }
    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public {
        baseTokenURI = _baseTokenURI;
    }
    function resetMintPrice() public {
        uint256 _latestPrice = getLatestPrice();
        _setEthPrice(_latestPrice);
        uint256 _unitRaise = unitRaise * 1e26 / 1000 * 1129;
        mintPrice = uint256(uint(_unitRaise) / uint(ethPrice));
        minMintPrice = uint256(mintPrice / 100 * 99);
        maxMintPrice = uint256(mintPrice / 100 * 101);
        return;
    }
    function getMintPrice() public view returns (uint256) {
        uint256 _latestPrice = getLatestPrice();
        uint256 _unitRaise = unitRaise * 1e26 / 1000 * 1129;
        return uint256(uint(_unitRaise) / uint(_latestPrice));
    }
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function _mintHandler(uint256 nftId) internal {
        mintedWallets[msg.sender]++;
        // totalSupply++;
        uint256 tokenId = nftId;
        string memory tokenURINeo = _concat(
            'https://gateway.pinata.cloud/ipfs/QmQFCEGhn82s4Dty8jU3DsXN2A5iZtP77EEXXsZjtL2rdz/',
            _uint2str(tokenId)
        );
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURINeo);
        _usedNftIds[nftId] = true;
        return;
    }
    function _concat(string memory _a, string memory _b) internal pure returns(string memory result) {
        return string(abi.encodePacked(_a, _b));
    }
    // TODO: Use the random ID generated from the backend, check if ID is used, reject if is, record if otherwise
    /// @notice Mint several tokens at once
    function mintBatch(
        uint256 number,
        string memory nonce,
        bytes32 hash,
        bytes memory signature,
        uint256[] memory nftIds
    ) external payable {
        resetMintPrice();
        // Prevent user mint any NFT before it starts
        require(isMintEnabled, 'minting not enabled');
        // Prevent user mint more NFTs than allowed
        require(mintedWallets[msg.sender] + number <= 5, 'exceeds max per wallet');
        // Prevent user mint more NFTs than total supply
        require(maxSupply > totalSupply() + 1, 'sold out');
        // signature related
        require(matchSigner(hash, signature), "Plz mint through website");
        require(!_usedNonces[nonce], "Hash reused");
        require(nftIds.length > 0, "NFT ID must be provided");
        for (uint256 j; j < nftIds.length; j++) {
            require(!_usedNftIds[nftIds[j]], "NFT has been minted");
        }
        bytes32 hash1 = hashTransaction(msg.sender, number, nonce, 1, nftIds);
        bytes32 hash2 = hashTransaction(msg.sender, number, nonce, 2, nftIds);
        bytes32 hash3 = hashTransaction(msg.sender, number, nonce, 3, nftIds);
        require(
            hash1 == hash || hash2 == hash || hash3 == hash,
            "Hash failed"
        );
        _usedNonces[nonce] = true;
        if (hash1 == hash || hash2 == hash) {
            // Prevent user from minting with wrong price
            require(msg.value > minMintPrice * number, 'wrong value');
            require(msg.value < maxMintPrice * number, 'wrong value');
        }
        if (hash3 == hash) {
            // Prevent user from minting with price, as it is free minting
            require(msg.value == 0, 'wrong value');
        }
        for (uint256 i; i < number; i++) {
            _mintHandler(nftIds[i]);
        }
    }
  
    function matchSigner(bytes32 hash, bytes memory signature) public view returns (bool) {
        address signer = hash.toEthSignedMessageHash().recover(signature);
        return _systemAddress == signer;
    }
    function hashTransaction(
        address sender,
        uint256 amount,
        string memory nonce,
        uint256 typeId,
        uint256[] memory nftIds
    ) public view returns (bytes32) {
    
        bytes32 hash = keccak256(
            abi.encodePacked(sender, amount, nonce, address(this), typeId, nftIds)
        );
        return hash;
    }
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
}