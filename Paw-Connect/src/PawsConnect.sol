// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { PawsBridge } from "./PawsBridge.sol";

/**
 * @title PawsConnect
 * @author Shikhar Agarwal
 * @notice This contract allows users to buy a cute pet from our branches and mint NFT for buying a pet
 * The NFT will be used to track the pet info and all related data for a particular pet corresponding to their token ids
 */
contract PawsConnect is ERC721 {
    struct PetInfo {
        string petName;
        string breed;
        string image;
        uint256 dob;
        address[] prevOwner;
        address shopPartner;
        uint256 idx;
    }

    // Storage Variables
    uint256 private pawsTokenCounter;
    address private immutable i_pawsConnectOwner;
    mapping(address => bool) private s_isPawsShop;
    address[] private s_pawsShops;
    mapping(address user => uint256[]) private s_ownerToPetsTokenId;
    mapping(uint256 tokenId => PetInfo) private s_petInfo;
    PawsBridge private immutable i_pawsBridge;

    // Events
    event ShopPartnerAdded(address partner);
    event PetMinted(uint256 tokenId, string petIpfsHash);
    event TokensRedeemedForVetVisit(uint256 tokenId, uint256 amount, string remarks);
    event PetTransferredToNewOwner(address prevOwner, address newOwner, uint256 tokenId);
    event NFTBridgeRequestSent(uint256 sourceChainId, uint64 destChainSelector, address destBridge, uint256 tokenId);
    event NFTBridged(uint256 chainId, uint256 tokenId);

    // Modifiers
    modifier onlyPawsConnectOwner() {
        require(msg.sender == i_pawsConnectOwner, "PawsConnect__NotPawsConnectOwner");
        _;
    }

    modifier onlyShopPartner() {
        require(s_isPawsShop[msg.sender], "PawsConnect__NotAPartner");
        _;
    }

    modifier onlyPawsBridge() {
        require(msg.sender == address(i_pawsBridge), "PawsConnect__NotPawsBridge");
        _;
    }

    // Constructor
    constructor(address[] memory initShops, address router, address link) ERC721("PawsConnect", "PC") {
        for (uint256 i = 0; i < initShops.length; i++) {
            s_pawsShops.push(initShops[i]);
            s_isPawsShop[initShops[i]] = true;
        }

        i_pawsConnectOwner = msg.sender;
        i_pawsBridge = new PawsBridge(router, link, msg.sender);
    }

    // Functions

    /**
     * @notice Allows the owner of the protocol to add a new shop partner
     * @param shopAddress The address of new shop partner
     */
    function addShop(address shopAddress) external onlyPawsConnectOwner {
        s_isPawsShop[shopAddress] = true;
        s_pawsShops.push(shopAddress);
        emit ShopPartnerAdded(shopAddress);
    }

    /**
     * @notice Allows the shop partners to mint a pet nft to owner when a purchase is made by user (pet owner)
     * @param petOwner The owner of new pet
     * @param petIpfsHash The image Ipfs Hash for the pet bought by petOwner
     * @param petName Name of pet
     * @param breed Breed of pet
     * @param dob timestamp of date of birth of pet (in seconds)
     * @dev Payments for the pet purchase takes off-chain and a corresponding NFT is minted to the owner which stores the info of pet
     */
    function mintPetToNewOwner(address petOwner, string memory petIpfsHash, string memory petName, string memory breed, uint256 dob) external onlyShopPartner {
        require(!s_isPawsShop[petOwner], "PawsConnect__PetOwnerCantBeShopPartner");

        uint256 tokenId = pawsTokenCounter;
        pawsTokenCounter++;

        s_petInfo[tokenId] = PetInfo({
            petName: petName,
            breed: breed,
            image: petIpfsHash,
            dob: dob,
            prevOwner: new address[](0),
            shopPartner: msg.sender,
            idx: s_ownerToPetsTokenId[petOwner].length
        });

        s_ownerToPetsTokenId[petOwner].push(tokenId);

        _safeMint(petOwner, tokenId);
        emit PetMinted(tokenId, petIpfsHash);
    }

    /**
     * @notice it is used to facilitate transfer of pet ownership to new owner
     * @notice but requires the approval of the pet owner to the new owner before shop partner calls this
     */
    function safeTransferFrom(address currPetOwner, address newOwner, uint256 tokenId, bytes memory data) public override onlyShopPartner {
        require(_ownerOf(tokenId) == currPetOwner, "PawsConnect__NotPetOwner");

        require(getApproved(tokenId) == newOwner, "PawsConnect__NewOwnerNotApproved");

        _updateOwnershipInfo(currPetOwner, newOwner, tokenId);

        emit PetTransferredToNewOwner(currPetOwner, newOwner, tokenId);
        _safeTransfer(currPetOwner, newOwner, tokenId, data);
    }

    function bridgeNftToAnotherChain(uint64 destChainSelector, address destChainBridge, uint256 tokenId) external {
        address petOwner = _ownerOf(tokenId);

        require(msg.sender == petOwner);

        PetInfo memory petInfo = s_petInfo[tokenId];
        uint256 idx = petInfo.idx;
        bytes memory data = abi.encode(petOwner, petInfo.petName, petInfo.breed, petInfo.image, petInfo.dob, petInfo.shopPartner);

        _burn(tokenId);
        delete s_petInfo[tokenId];

        uint256[] memory userTokenIds = s_ownerToPetsTokenId[msg.sender];
        uint256 lastItem = userTokenIds[userTokenIds.length - 1];

        s_ownerToPetsTokenId[msg.sender].pop();

        if (idx < (userTokenIds.length - 1)) {
            s_ownerToPetsTokenId[msg.sender][idx] = lastItem;
        }

        emit NFTBridgeRequestSent(block.chainid, destChainSelector, destChainBridge, tokenId);
        i_pawsBridge.bridgeNftWithData(destChainSelector, destChainBridge, data);
    }

    function mintBridgedNFT(bytes memory data) external onlyPawsBridge {
        (
            address petOwner, 
            string memory petName, 
            string memory breed, 
            string memory imageIpfsHash, 
            uint256 dob, 
            address shopPartner
        ) = abi.decode(data, (address, string, string, string, uint256, address));

        uint256 tokenId = pawsTokenCounter;
        pawsTokenCounter++;

        s_petInfo[tokenId] = PetInfo({
            petName: petName,
            breed: breed,
            image: imageIpfsHash,
            dob: dob,
            prevOwner: new address[](0),
            shopPartner: shopPartner,
            idx: s_ownerToPetsTokenId[petOwner].length
        });

        emit NFTBridged(block.chainid, tokenId);
        _safeMint(petOwner, tokenId);
    }

    function _updateOwnershipInfo(address currPetOwner, address newOwner, uint256 tokenId) internal {        
        s_petInfo[tokenId].prevOwner.push(currPetOwner);
        s_petInfo[tokenId].idx = s_ownerToPetsTokenId[newOwner].length;
        s_ownerToPetsTokenId[newOwner].push(tokenId);
    }


    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    /**
     * @notice returns the token uri of the corresponding pet nft
     * @param tokenId The token id of pet
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        PetInfo memory petInfo = s_petInfo[tokenId];

        string memory petTokenUri = Base64.encode(
            abi.encodePacked(
                '{"name": "', petInfo.petName,
                '", "breed": "', petInfo.breed,
                '", "image": "', petInfo.image,
                '", "dob": ', Strings.toString(petInfo.dob),
                ', "owner": "', Strings.toHexString(_ownerOf(tokenId)),
                '", "shopPartner": "', Strings.toHexString(petInfo.shopPartner),
                '"}'
            )
        );
        return string.concat(_baseURI(), petTokenUri);
    }

    /**
     * @notice Returns the age of pet in seconds
     * @param tokenId The token id of pet
     */
    function getPetAge(uint256 tokenId) external view returns (uint256) {
        return block.timestamp - s_petInfo[tokenId].dob;
    }
    
    function getTokenCounter() external view returns (uint256) {
        return pawsTokenCounter;
    }

    function getPawsConnectOwner() external view returns (address) {
        return i_pawsConnectOwner;
    }

    function getAllPawsShops() external view returns (address[] memory) {
        return s_pawsShops;
    }

    function getPawsShopAtIdx(uint256 idx) external view returns (address) {
        return s_pawsShops[idx];
    }

    function getIsPawsPartnerShop(address partnerShop) external view returns (bool) {
        return s_isPawsShop[partnerShop];
    }

    function getPetInfo(uint256 tokenId) external view returns (PetInfo memory) {
        return s_petInfo[tokenId];
    }

    function getPetsTokenIdOwnedBy(address user) external view returns (uint256[] memory) {
        return s_ownerToPetsTokenId[user];
    }

    function getPawsBridge() external view returns (address) {
        return address(i_pawsBridge);
    }
}
