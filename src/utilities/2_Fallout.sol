01  // SPDX-License-Identifier: MIT
02  pragma solidity ^0.6.0;
03  
04  import 'openzeppelin-contracts-06/math/SafeMath.sol';
05  
06  contract Fallout {
07    
08    using SafeMath for uint256;
09    mapping (address => uint) allocations;
10    address payable public owner;
11  
12  
13    /* constructor */
14    function Fal1out() public payable {
15      owner = msg.sender;
16      allocations[owner] = msg.value;
17    }
18  
19    modifier onlyOwner {
20  	        require(
21  	            msg.sender == owner,
22  	            "caller is not the owner"
23  	        );
24  	        _;
25  	    }
26  
27    function allocate() public payable {
28      allocations[msg.sender] = allocations[msg.sender].add(msg.value);
29    }
30  
31    function sendAllocation(address payable allocator) public {
32     require(allocations[allocator] > 0);
33     allocator.transfer(allocations[allocator]);
34    }
35  
36    function collectAllocations() public onlyOwner {
37      msg.sender.transfer(address(this).balance);
38    }
39  
40    function allocatorBalance(address allocator) public view returns (uint) {
41      return allocations[allocator];
42    }
43  }