// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from
    "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";

abstract contract PawsBridgeBase {
    error PawsBridge__NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    error PawsBridge__NothingToWithdraw();
    error PawsBridge__FailedToWithdrawEth(address owner, address target, uint256 value);
    error PawsBridge__DestinationChainNotAllowlisted(uint64 destinationChainSelector);
    error PawsBridge__SourceChainNotAllowlisted(uint64 sourceChainSelector);
    error PawsBridge__SenderNotAllowlisted(address sender);
    error PawsBridge__InvalidReceiverAddress();
    error PawsBridge__NotPawsConnect();

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        bytes data,
        address feeToken,
        uint256 fees
    );

    event MessageReceived(bytes32 indexed messageId, uint64 indexed sourceChainSelector, address sender, bytes data);

    uint256 internal gaslimit;
    mapping(uint64 => bool) public allowlistedDestinationChains;
    mapping(uint64 => bool) public allowlistedSourceChains;
    mapping(address => bool) public allowlistedSenders;
    IERC20 internal s_linkToken;
    address internal PawsConnect;

    modifier onlyAllowlistedDestinationChain(uint64 _destinationChainSelector) {
        if (!allowlistedDestinationChains[_destinationChainSelector]) {
            revert PawsBridge__DestinationChainNotAllowlisted(_destinationChainSelector);
        }
        _;
    }

    modifier onlyAllowlisted(uint64 _sourceChainSelector, address _sender) {
        if (!allowlistedSourceChains[_sourceChainSelector]) {
            revert PawsBridge__SourceChainNotAllowlisted(_sourceChainSelector);
        }
        if (!allowlistedSenders[_sender]) revert PawsBridge__SenderNotAllowlisted(_sender);
        _;
    }

    modifier validateReceiver(address _receiver) {
        if (_receiver == address(0)) revert PawsBridge__InvalidReceiverAddress();
        _;
    }

    modifier onlyPawsConnect() {
        if (msg.sender != PawsConnect) {
            revert PawsBridge__NotPawsConnect();
        }
        _;
    }
}