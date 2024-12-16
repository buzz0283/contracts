// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BuzzPayment is Ownable, ReentrancyGuard {

    struct TokenInfo {
        bool isSupported;
        uint256 payAmount;
    }
  
    uint256 public nativePayAmount;
    address public cashier;
    mapping(address => TokenInfo) public supportedTokens;
    
    event PaymentReceived(address payer, address token, uint256 amount, uint256 uId);
    event CashierUpdated(address _cashier);
    event TokenUpdated(address token, bool status, uint256 amount);
    event NativePayAmountUpdated(uint256 amount);

    constructor() Ownable(msg.sender) {}

    function setCashier(address _cashier) external onlyOwner {
        require(_cashier != address(0), "Invalid admin address");
        cashier = _cashier;
        emit CashierUpdated(_cashier);
    }

    function setSupportedToken(address token, bool status, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        supportedTokens[token] = TokenInfo({
            isSupported: status,
            payAmount: amount
        });
        emit TokenUpdated(token, status, amount);
    }


    function payERC20(
        uint256 uId,
        uint256 amount,
        address token
    ) external nonReentrant {
        TokenInfo memory tokenInfo = supportedTokens[token];
        require(tokenInfo.isSupported, "Token not supported");
        require(amount == tokenInfo.payAmount, "Invalid payment amount");
    
        require(IERC20(token).transferFrom(msg.sender, cashier, amount), "Transfer failed");
        
        emit PaymentReceived(msg.sender, token, amount, uId);
    }


    // 添加设置原生币支付金额的函数
    function setNativePayAmount(uint256 amount) external onlyOwner {
        nativePayAmount = amount;
        emit NativePayAmountUpdated(amount);
    }

    // 添加原生币支付函数
    function payNative(
        uint256 uId
    ) external payable nonReentrant {
        require(msg.value == nativePayAmount, "Invalid payment amount");
        
        (bool success, ) = payable(cashier).call{value: msg.value}("");
        require(success, "Transfer failed");
        
        emit PaymentReceived(msg.sender, address(0), msg.value, uId);
    }

    receive() external payable {}
    fallback() external payable {}
}