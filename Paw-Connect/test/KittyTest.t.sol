// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { DeployPawsConnect } from "../script/DeployPawsConnect.s.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { PawsConnect } from "../src/PawsConnect.sol";
import { PawsBridge, PawsBridgeBase, Client } from "../src/PawsBridge.sol";

contract PawsTest is Test {
    PawsConnect PawsConnect;
    PawsBridge PawsBridge;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    address PawsConnectOwner;
    address partnerA;
    address partnerB;
    address user;
    address ethUsdPriceFeed;

    event ShopPartnerAdded(address partner);
    event CatMinted(uint256 tokenId, string catIpfsHash);
    event TokensRedeemedForVetVisit(uint256 tokenId, uint256 amount, string remarks);
    event CatTransferredToNewOwner(address prevOwner, address newOwner, uint256 tokenId);

    function setUp() external {
        DeployPawsConnect deployer = new DeployPawsConnect();
        
        (PawsConnect, helperConfig) = deployer.run();
        networkConfig = helperConfig.getNetworkConfig();

        PawsConnectOwner = PawsConnect.getPawsConnectOwner();
        partnerA = PawsConnect.getPawsShopAtIdx(0);
        partnerB = PawsConnect.getPawsShopAtIdx(1);
        PawsBridge = PawsBridge(PawsConnect.getPawsBridge());
        user = makeAddr("user");
    }

    function testConstructor() public {
        address[] memory partners = networkConfig.initShopPartners;

        assertEq(partnerA, partners[0]);
        assertEq(partnerB, partners[1]);
        assert(PawsConnect.getIsPawsPartnerShop(partnerA) == true);
    }

    function test_onlyShopPartnersCanAllocateCatToUsers() public {
        address someUser = makeAddr("someUser");
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        vm.expectRevert("PawsConnect__NotAPartner");
        vm.prank(someUser);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Hehe", "Hehe", block.timestamp);
    }

    function test_mintCatToNewOwnerIfCatOwnerIsShopPartner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        vm.expectRevert("PawsConnect__CatOwnerCantBeShopPartner");
        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(partnerB, catImageIpfsHash, "Hehe", "Hehe", block.timestamp);
    }
    
    function test_ShopPartnerGivesCatToCustomer() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        vm.warp(block.timestamp + 10 weeks);

        uint256 tokenId = PawsConnect.getTokenCounter();

        vm.expectEmit(false, false, false, true);
        emit CatMinted(tokenId, catImageIpfsHash);
        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp - 3 weeks);

        string memory tokenUri = PawsConnect.tokenURI(tokenId);
        console.log(tokenUri);
        PawsConnect.CatInfo memory catInfo = PawsConnect.getCatInfo(tokenId);
        uint256[] memory userCatTokenId = PawsConnect.getCatsTokenIdOwnedBy(user);

        assertEq(PawsConnect.ownerOf(tokenId), user);
        assertEq(PawsConnect.getTokenCounter(), tokenId + 1);
        assertEq(userCatTokenId[0], tokenId);
        assertEq(catInfo.catName, "Meowdy");
        assertEq(catInfo.breed, "Ragdoll");
        assertEq(catInfo.image, catImageIpfsHash);
        assertEq(catInfo.dob, block.timestamp - 3 weeks);
        assertEq(catInfo.shopPartner, partnerA);
        assertEq(catInfo.idx, 0);
    }

    function test_getCatAge() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        uint256 tokenId = PawsConnect.getTokenCounter();

        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        
        vm.warp(block.timestamp + 10 weeks);
        vm.prank(user);
        uint256 catAge = PawsConnect.getCatAge(tokenId);

        assertEq(catAge, 10 weeks);
    }

    function test_onlyPawsConnectOwnerCanAddNewPartnerShop() public {
        address partnerC = makeAddr("partnerC");

        vm.prank(PawsConnectOwner);
        PawsConnect.addShop(partnerC);

        assertEq(PawsConnect.getPawsShopAtIdx(2), partnerC);
    }

    function test_revertsIfCallerIsNotPawsConnectOwner() public {
        address partnerC = makeAddr("partnerC");

        vm.expectRevert("PawsConnect__NotPawsConnectOwner");
        vm.prank(partnerC);
        PawsConnect.addShop(partnerC);
    }

    function test_tokenURI() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        string memory expectedTokenURI = "data:application/json;base64,eyJuYW1lIjogTWVvd2R5IiwgImJyZWVkIjogUmFnZG9sbCIsICJpbWFnZSI6IGlwZnM6Ly9RbWJ4d0dnQkdyTmRYUG04NGtxWXNrbWNNVDNqcnpCTjhMelFqaXh2a3o0YzYyIiwgImRvYiI6IDEsICJvd25lciI6IDB4NmNhNmQxZTJkNTM0N2JmYWIxZDkxZTg4M2YxOTE1NTYwZTA5MTI5ZCIsICJzaG9wUGFydG5lciI6IDB4NzA5OTc5NzBjNTE4MTJkYzNhMDEwYzdkMDFiNTBlMGQxN2RjNzljOCJ9";
        uint256 tokenId = PawsConnect.getTokenCounter();
        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        string memory tokenUri = PawsConnect.tokenURI(tokenId);

        assertEq(tokenUri, expectedTokenURI);
    }

    modifier partnerGivesCatToOwner() {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        // Shop Partner gives Cat to user
        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        _;
    }

    function test_transferCatToNewOwner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        uint256 tokenId = PawsConnect.getTokenCounter();
        address newOwner = makeAddr("newOwner");

        // Shop Partner gives Cat to user
        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        // Now user wants to transfer the cat to a new owner
        // first user approves the cat's token id to new owner
        vm.prank(user);
        PawsConnect.approve(newOwner, tokenId);

        // then the shop owner checks up with the new owner and confirms the transfer
        vm.expectEmit(false, false, false, true, address(PawsConnect));
        emit CatTransferredToNewOwner(user, newOwner, tokenId);
        vm.prank(partnerA);
        PawsConnect.safeTransferFrom(user, newOwner, tokenId);

        uint256[] memory newOwnerTokenIds = PawsConnect.getCatsTokenIdOwnedBy(newOwner);
        PawsConnect.CatInfo memory catInfo = PawsConnect.getCatInfo(tokenId);
        string memory tokenUri = PawsConnect.tokenURI(tokenId);
        console.log(tokenUri);


        assert(PawsConnect.getCatsTokenIdOwnedBy(user).length == 0);
        assert(newOwnerTokenIds.length == 1);
        assertEq(newOwnerTokenIds[0], tokenId);
        assertEq(catInfo.prevOwner[0], user);
    }

    function test_transferCatReverts_If_CallerIsNotAPartnerShop() public partnerGivesCatToOwner {
        uint256 tokenId = PawsConnect.getTokenCounter() - 1;
        address newOwner = makeAddr("newOwner");
        address notPartnerShop = makeAddr("notPartnerShop");

        vm.prank(user);
        PawsConnect.approve(newOwner, tokenId);

        vm.prank(notPartnerShop);
        vm.expectRevert("PawsConnect__NotAPartner");
        PawsConnect.safeTransferFrom(user, newOwner, tokenId);
    }

    function test_safetransferCatToNewOwner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        uint256 tokenId = PawsConnect.getTokenCounter();
        address newOwner = makeAddr("newOwner");

        vm.prank(partnerA);
        PawsConnect.mintCatToNewOwner(user, catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        vm.prank(user);
        PawsConnect.approve(newOwner, tokenId);

        vm.expectEmit(false, false, false, true, address(PawsConnect));
        emit CatTransferredToNewOwner(user, newOwner, tokenId);
        vm.prank(partnerA);
        PawsConnect.safeTransferFrom(user, newOwner, tokenId);

        assertEq(PawsConnect.ownerOf(tokenId), newOwner);
        assertEq(PawsConnect.getCatsTokenIdOwnedBy(user).length, 0);
        assertEq(PawsConnect.getCatsTokenIdOwnedBy(newOwner).length, 1);
        assertEq(PawsConnect.getCatsTokenIdOwnedBy(newOwner)[0], tokenId);
        assertEq(PawsConnect.getCatInfo(tokenId).prevOwner[0], user);
        assertEq(PawsConnect.getCatInfo(tokenId).prevOwner.length, 1);
        assertEq(PawsConnect.getCatInfo(tokenId).idx, 0);
    }

    // PawsBridge Tests
    function test_PawsBridgeConstructor() public {
        address mockLinkToken = 0x90193C961A926261B756D1E5bb255e67ff9498A1;

        assertEq(PawsBridge.getPawsConnectAddr(), address(PawsConnect));
        assertEq(PawsBridge.getGaslimit(), 400000);
        assertEq(PawsBridge.getLinkToken(), mockLinkToken);
    }

    function test_gasForCcipReceive() public {
        address sender = makeAddr("sender");
        bytes memory data = abi.encode(makeAddr("catOwner"), "meowdy", "ragdoll", "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62", block.timestamp, partnerA);

        vm.prank(PawsConnectOwner);
        PawsBridge.allowlistSender(networkConfig.router, true);

        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: bytes32(0),
            sourceChainSelector: networkConfig.otherChainSelector,
            sender: abi.encode(sender),
            data: data,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        vm.prank(networkConfig.router);

        uint256 initGas = gasleft();
        PawsBridge.ccipReceive(message);

        uint256 finalGas = gasleft();

        uint256 gasUsed = initGas - finalGas;

        console.log("Gas Used -", gasUsed);
    }

    function test_allowlistSenderIsNotOwner() public {
        address sender = makeAddr("sender");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(sender);
        PawsBridge.allowlistSender(sender, true);
    }

    function test_allowlistSender() public {
        address sender = makeAddr("sender");

        vm.prank(PawsConnectOwner);
        PawsBridge.allowlistSender(sender, true);

        assert(PawsBridge.allowlistedSenders(sender) == true);
    }

    function test_allowlistDestinationChain() public {
        uint64 chainId = 1;

        vm.prank(PawsConnectOwner);
        PawsBridge.allowlistDestinationChain(chainId, true);

        assert(PawsBridge.allowlistedDestinationChains(chainId) == true);
    }

    function test_allowlistDestinationChainIsNotOwner() public {
        uint64 chainId = 1;
        address  attacker = makeAddr("attacker");   

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(attacker);
        PawsBridge.allowlistDestinationChain(chainId, true);
    }

    function test_allowlistSourceChain() public {
        uint64 chainId = 1;

        vm.prank(PawsConnectOwner);
        PawsBridge.allowlistSourceChain(chainId, true);

        assert(PawsBridge.allowlistedSourceChains(chainId) == true);
    }

    function test_allowlistSourceChainRevertIfNotOwner() public {
        uint64 chainId = 1;
        address attacker = makeAddr("attacker");
        
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(attacker);
        PawsBridge.allowlistSourceChain(chainId, true);

    }

    function test_bridgeNftWithDataIfDestinationIsNotAllowlisted() public {
        address sender = makeAddr("sender");
        uint64 chainId = 1;
        bytes memory data = abi.encode(makeAddr("catOwner"), "meowdy", "ragdoll", "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62", block.timestamp, partnerA);

        vm.expectRevert(abi.encodeWithSelector(PawsBridgeBase.PawsBridge__DestinationChainNotAllowlisted.selector, chainId));
        vm.prank(address(PawsConnect));
        PawsBridge.bridgeNftWithData(chainId, sender, data);
    }

    function test_updateGaslimit() public {
        uint256 newGaslimit = 500000;

        vm.prank(PawsConnectOwner);
        PawsBridge.updateGaslimit(newGaslimit);

        assertEq(PawsBridge.getGaslimit(), newGaslimit);
    }

    function test_updateGaslimitRevertIfNotOwner() public {
        uint256 newGaslimit = 500000;
        address attacker = makeAddr("attacker");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(attacker);
        PawsBridge.updateGaslimit(newGaslimit);
    }
}