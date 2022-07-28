//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";

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
    mapping(string => bool) public _usedUrls;

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

    function _mintHandler() internal {

        mintedWallets[msg.sender]++;

        // totalSupply++;

        uint256 tokenId = totalSupply() + 1;

        string memory tokenURINeo = _concat(
            'https://gateway.pinata.cloud/ipfs/QmQFCEGhn82s4Dty8jU3DsXN2A5iZtP77EEXXsZjtL2rdz/',
            _uint2str(tokenId)
        );

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, tokenURINeo);

        return;
    }

    function _concat(string memory _a, string memory _b) internal pure returns(string memory result) {
        return string(abi.encodePacked(_a, _b));
    }

    /// @notice Mint several tokens at once
    function mintBatch(
        uint256 number,
        string memory nonce,
        bytes32 hash,
        bytes memory signature
    ) external payable {
        resetMintPrice();
        // Prevent user mint any NFT before it starts
        require(isMintEnabled, 'minting not enabled');
        // Prevent user mint more NFTs than allowed
        require(mintedWallets[msg.sender] + number <= 5, 'exceeds max per wallet');
        // Prevent user from minting with wrong price
        // require(msg.value == mintPrice * number, 'wrong value');
        require(msg.value > minMintPrice * number, 'wrong value');
        require(msg.value < maxMintPrice * number, 'wrong value');
        // Prevent user mint more NFTs than total supply
        require(maxSupply > totalSupply() + 1, 'sold out');

        // signature related
        require(!_usedNonces[nonce], "Hash reused");
        require(
            hashTransaction(msg.sender, 1, nonce) == hash,
            "Hash failed"
        );
        // TODO: Check if the signature is in the format of free mint.
        // If is, proceed with free mint matcher
        // Otherwise, proceed with normal matcher
        // Or we may consider making a separated mint function for free mint
        // As we removed the single mint function, this may be working
        // But we still at the risk of going oversize 
        // string recoveredSig = hash.toEthSignedMessageHash().recover(signature);
        // if (recoveredSig.contains("-"))
        require(matchSigner(hash, signature), "Plz mint through website");

        _usedNonces[nonce] = true;

        for (uint256 i; i < number; i++) {
            _mintHandler();
        }
    }
  
    function matchSigner(bytes32 hash, bytes memory signature) public view returns (bool) {
        return _systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }
  
    function matchSignerFreeMint(bytes32 hash, bytes memory signature) public view returns (bool) {
        string[] strArray = _slice(hash.toEthSignedMessageHash().recover(signature));
        return (
            _systemAddress == strArray[0] &&
            !_usedUrls[strArray[1]]
        );
    }

    // Check if a string contains a symbol
    // If we are going to separate mint function, this will be removed.
    function _contains (string memory what, string memory where) internal returns (bool){
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        require(whereBytes.length >= whatBytes.length);

        bool found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
        require (found);

        _;
    }

    function hashTransaction(
        address sender,
        uint256 amount,
        string memory nonce
    ) public view returns (bytes32) {
    
        bytes32 hash = keccak256(
        abi.encodePacked(sender, amount, nonce, address(this))
        );

        return hash;
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

    // Slice a string with "-"
    // Unsure if it is going to work
    function _slice(string strInput) internal pure returns(string[] memory) {                                               
        strings.slice memory s = strInput.toSlice();                
        strings.slice memory delim = "-".toSlice();                            
        string[] memory parts = new string[](s.count(delim));                  
        for (uint i = 0; i < parts.length; i++) {                              
           parts[i] = s.split(delim).toString();                               
        }
        return parts;
    }


}