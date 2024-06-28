// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "hardhat/console.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract Vault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IWETH public weth;
    bool private _isWithdrawing;

    mapping(address => uint256) private ethBalances;
    mapping(address => mapping(address => uint256)) private tokenBalances;

    error Vault__InsufficientETHBalance(uint256 requested, uint256 available);
    error Vault__InsufficientTokenBalance(uint256 requested, uint256 available);
    error Vault__DepositAmountZero();

    constructor(IWETH _weth) {
        weth = _weth;
    }

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable nonReentrant {
        if (msg.value == 0) revert Vault__DepositAmountZero();
        ethBalances[msg.sender] += msg.value;
    }

    function withdrawETH(uint256 amount) public nonReentrant {
        if (ethBalances[msg.sender] < amount)
            revert Vault__InsufficientETHBalance(
                amount,
                ethBalances[msg.sender]
            );
        ethBalances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function depositToken(address token, uint256 amount) public nonReentrant {
        if (amount == 0) revert Vault__DepositAmountZero();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        tokenBalances[msg.sender][token] += amount;
    }

    function withdrawToken(address token, uint256 amount) public nonReentrant {
        if (tokenBalances[msg.sender][token] < amount)
            revert Vault__InsufficientTokenBalance(
                amount,
                tokenBalances[msg.sender][token]
            );
        tokenBalances[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function wrapETH(uint256 amount) public nonReentrant {
        if (ethBalances[msg.sender] < amount)
            revert Vault__InsufficientETHBalance(
                amount,
                ethBalances[msg.sender]
            );
        ethBalances[msg.sender] -= amount;
        weth.deposit{value: amount}();
        tokenBalances[msg.sender][address(weth)] += amount;
    }

    function unwrapWETH(uint256 amount) public nonReentrant {
        if (tokenBalances[msg.sender][address(weth)] < amount)
            revert Vault__InsufficientTokenBalance(
                amount,
                tokenBalances[msg.sender][address(weth)]
            );
        tokenBalances[msg.sender][address(weth)] -= amount;

        IWETH wethContract = IWETH(weth);
        try wethContract.withdraw(amount) {
            // Success
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Unknown error");
        }

        ethBalances[msg.sender] += amount;
    }

    function getETHBalance(address account) external view returns (uint256) {
        return ethBalances[account];
    }

    function getTokenBalance(
        address account,
        address token
    ) external view returns (uint256) {
        return tokenBalances[account][token];
    }
}
