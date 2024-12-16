// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BuzzVault {
    address public admin;
    IERC20 public token;

    event Withdrawal(address indexed recipient, uint256 amount);

    constructor(address _admin, address _tokenAddress) {
        admin = _admin;
        token = IERC20(_tokenAddress);
    }

    function withdraw(address payable recipient, uint256 amount) external {
        require(msg.sender == admin, "Only admin can withdraw");
        token.transfer(recipient, amount);
        emit Withdrawal(recipient, amount);
    }

    receive() external payable {}

    fallback() external payable {}

}
