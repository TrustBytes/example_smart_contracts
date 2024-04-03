01  // SPDX-License-Identifier: MIT
02  pragma solidity ^0.8.0;
03  
04  contract Telephone {
05  
06    address public owner;
07  
08    constructor() {
09      owner = msg.sender;
10    }
11  
12    function changeOwner(address _owner) public {
13      if (tx.origin != msg.sender) {
14        owner = _owner;
15      }
16    }
17  }