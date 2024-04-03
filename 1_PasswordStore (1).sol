01  // SPDX-License-Identifier: MIT
02  pragma solidity 0.8.18;
03 
04  /*
05  * @author not-so-secure-dev
06   * @title PasswordStore
07   * @notice This contract allows you to store a private password that others won't be able to see. 
08   * You can update your password at any time.
09  */
10  contract PasswordStore {
11      error PasswordStore__NotOwner();
12  
13      address private s_owner;
14      string private s_password;
15  
16      event SetNetPassword();
17  
18      constructor() {
19          s_owner = msg.sender;
20      }
21 
22      /*
23       * @notice This function allows only the owner to set a new password.
24       * @param newPassword The new password to set.
25       */
26      function setPassword(string memory newPassword) external {
27          s_password = newPassword;
28          emit SetNetPassword();
29      }
31  
32     /*
33       * @notice This allows only the owner to retrieve the password.
34       * @param newPassword The new password to set.
35       */
36      function getPassword() external view returns (string memory) {
37          if (msg.sender != s_owner) {
38              revert PasswordStore__NotOwner();
39          }
40          return s_password;
41      }
42  }
43  