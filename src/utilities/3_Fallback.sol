01  // SPDX-License-Identifier: MIT
02  pragma solidity ^0.8.0;
03  
04  contract Fallback {
05  
06    mapping(address => uint) public contributions;
07    address public owner;
08  
09    constructor() {
10      owner = msg.sender;
11      contributions[msg.sender] = 1000 * (1 ether);
12    }
13  
14    modifier onlyOwner {
15          require(
16              msg.sender == owner,
17              "caller is not the owner"
18          );
19          _;
20      }
21  
22    function contribute() public payable {
23      require(msg.value < 0.001 ether);
24      contributions[msg.sender] += msg.value;
25      if(contributions[msg.sender] > contributions[owner]) {
26        owner = msg.sender;
27      }
28    }
29  
30    function getContribution() public view returns (uint) {
31      return contributions[msg.sender];
32    }
33  
34    function withdraw() public onlyOwner {
35      payable(owner).transfer(address(this).balance);
36    }
37  
38    receive() external payable {
39      require(msg.value > 0 && contributions[msg.sender] > 0);
40      owner = msg.sender;
41    }
42  }