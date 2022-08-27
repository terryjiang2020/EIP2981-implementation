//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract MyContract is ERC721Enumerable, Ownable, ReentrancyGuard {
    function getLatestPrice() public view returns (uint256) {
        (
            , 
            int256 price,
            ,
            ,
            
        ) = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).latestRoundData();
        return uint256(price);
    }
    // NFT contract starts
    // https://www.youtube.com/watch?v=8WPzUbJyoNg
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }
    RoyaltyInfo private _royalties;
    uint256 public mintPrice = 0;
    uint256 public minMintPrice = 0;
    uint256 public maxMintPrice = 0;
    uint256 public ethPrice = 0;
    uint256 public unitRaise = 10500 / 375;
    uint256 public maxSupply = 375;
    bool public isMintEnabled;
    bool public reEntrancyMutex;
    mapping(address => uint256) public mintedWallets;
    // Disabled as whitelist would be stored in server instead of here
    // mapping(address => bool) whitelistedAddresses;
    mapping(string => bool) private _usedNonces;
    mapping(uint256 => bool) private _usedNftIds;
    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI = 
        'https://ipfs.io/ipfs/QmXLnc5BtTPHfS3ZB3X15WHZZ6XHqtVsCab1CS83gERk3a/';
    using ECDSA for bytes32;
    address private constant _systemAddress = 0x8E14b52bCA3b9d4c82174113089682fD6c5a53Ba;
    // ERC721URIStorage.sol
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    constructor() payable ERC721('Baby Supe', 'BABYSUPE') {
        // 375 NFT for maximum
        maxSupply = 375; 
        _setRoyalties(msg.sender, 350);
        resetMintPrice();
    }
    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
        resetMintPrice();
    }
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
        unitRaise = 10500 / maxSupply;
    }
    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    function resetMintPrice() public {
        ethPrice = getLatestPrice();
        mintPrice = uint256(uint(unitRaise / 1000 * 1e26 * 1129) / uint(ethPrice));
        minMintPrice = uint256(mintPrice / 100 * 99);
        maxMintPrice = uint256(mintPrice / 100 * 101);
        return;
    }
    function getMintPrice() external view returns (uint256) {
        return uint256(uint(unitRaise / 1000 * 1e26 * 1129) / uint(getLatestPrice()));
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

        require(_exists(nftId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[nftId] = string(abi.encodePacked(_uint2str(nftId), '.json'));
        _usedNftIds[nftId] = true;
        _safeMint(msg.sender, nftId);
        return;
    }
    // Disabled as whitelist would be stored in server instead of here
    // function addUser(address _addressToWhitelist) public onlyOwner {
    //     whitelistedAddresses[_addressToWhitelist] = true;
    // }
    // TODO: Use the random ID generated from the backend, check if ID is used, reject if is, record if otherwise
    /// @notice Mint several tokens at once
    function mintBatch(
        uint256 number,
        string memory nonce,
        bytes32 hash,
        bytes memory signature,
        uint256[] memory nftIds,
        uint256 typeId
    ) external payable nonReentrant callerIsUser {
        // Prevent replay attack
        // Prevent user mint any NFT before it starts
        require(
            !reEntrancyMutex && isMintEnabled,
            'Another mint process has not ended OR minting not enabled'
        );
        reEntrancyMutex = true;
        // Update to the latest mint price
        resetMintPrice();
        // Prevent user mint more NFTs than allowed
        // Prevent user mint more NFTs than total supply
        require(
            mintedWallets[msg.sender] + number <= 5 && maxSupply > totalSupply() + 1,
            'Exceeds max per wallet OR NFT sold out'
        );
        // Check signature
        require(_matchSigner(hash, signature), "Please mint through website");
        // Check input validity
        // One mint can have upto 5 NFTs
        // NFT ID array must have the length same as minting amount
        // Type ID must be 1, 2 or 3
        require(
            nftIds.length > 0 && number > 0 && number <= 5 && nftIds.length == number &&
            typeId > 0 && typeId <= 3,
            "Invalid input"
        );
        for (uint256 j = 0; j < nftIds.length; j++) {
            require(!_usedNftIds[nftIds[j]], "NFT has been minted");
        }
        // Check hash validity
        // Check if nonce is reused
        require(
            _hashTransaction(msg.sender, number, nonce, typeId, nftIds) == hash && !_usedNonces[nonce],
            "Hash incorrect or reused"
        );
        _usedNonces[nonce] = true;
        // typeId
        // 1: Normal
        // 2: Whitelist
        // 3: Purchased (paid by credit card, preordered, is a free mint member, etc.)
        if (typeId == 1 || typeId == 2) {
            // Prevent user from minting with wrong price
            require(
                msg.value > minMintPrice * number && msg.value < maxMintPrice * number,
                'Wrong value'
            );
        }
        // Disabled as whitelist would be stored in server instead of here
        // if (typeId == 2) {
        //     // Check if user is in whitelist
        //     require(whitelistedAddresses[msg.sender], "You need to be whitelisted");
        // }
        if (typeId == 3) {
            // Prevent user from minting with price, as it is free minting
            require(msg.value == 0, 'wrong value');
        }
        if (msg.value != 0) {
            require(_systemAddress != address(0), 'System Address not given');
            payable(_systemAddress).transfer(msg.value);
        }
        for (uint256 i = 0; i < number; ++i) {
            _mintHandler(nftIds[i]);
        }
        reEntrancyMutex = false;
    }
  
    // Check if the signer is Senkusha.
    // If not, the mintng is not going through us.
    function _matchSigner(bytes32 hash, bytes memory signature) internal pure returns (bool) {
        return _systemAddress == hash.toEthSignedMessageHash().recover(signature);
    }
    // Generate the hash with the given data.
    // The data won't be matching if user try to modify it before sending request.
    function _hashTransaction(
        address sender,
        uint256 amount,
        string memory nonce,
        uint256 typeId,
        uint256[] memory nftIds
    ) internal view returns (bytes32) {
    
        return keccak256(
            abi.encodePacked(sender, amount, nonce, address(this), typeId, nftIds)
        );
    }
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseTokenURI;
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
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external virtual nonReentrant callerIsUser {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
        // Disabled because
        // Adding it would exceed the contract size
        // As a result, the metadata (image, name, etc.) will remain on chain after burning.
        // The token itself will be in a null wallet after burning.
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
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}