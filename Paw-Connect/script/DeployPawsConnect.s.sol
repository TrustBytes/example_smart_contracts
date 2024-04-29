// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {PawsConnect} from "../src/PawsConnect.sol";
import {PawsBridge} from "../src/PawsBridge.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

contract DeployPawsConnect is Script {
    function run() external returns (PawsConnect, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getNetworkConfig();
        PawsBridge PawsBridge;
        uint256 linkBalance = 8 ether;   // 8 link

        vm.startBroadcast();

        PawsConnect PawsConnect =
        new PawsConnect(networkConfig.initShopPartners, networkConfig.router, networkConfig.link);

        PawsBridge = PawsBridge(PawsConnect.getPawsBridge());
        PawsBridge.allowlistDestinationChain(networkConfig.otherChainSelector, true);
        PawsBridge.allowlistSourceChain(networkConfig.otherChainSelector, true);
        
        IERC20(networkConfig.link).transfer(address(PawsBridge), linkBalance);

        vm.stopBroadcast();

        return (PawsConnect, helperConfig);
    }
}
