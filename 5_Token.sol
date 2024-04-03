01  // SPDX-License-Identifier: MIT
02  pragma solidity ^0.6.0;
03  
04  contract Token {
05  
06    mapping(address => uint) balances;
07    uint public totalSupply;
08  
09    constructor(uint _initialSupply) public {
10      balances[msg.sender] = totalSupply = _initialSupply;
11    }
12  
13    function transfer(address _to, uint _value) public returns (bool) {
14      require(balances[msg.sender] - _value >= 0);
15      balances[msg.sender] -= _value;
16      balances[_to] += _value;
17      return true;
18    }
19  
20    function balanceOf(address _owner) public view returns (uint balance) {
21      return balances[_owner];
22    }
23  }