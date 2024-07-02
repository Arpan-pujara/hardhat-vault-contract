// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Vault {
    using SafeERC20 for IERC20;
    using Address for address payable;

    mapping(address => uint256) private ethBalances;
    mapping(address => mapping(address => uint256)) private tokenBalances;

    address public immutable WETH;

    event DepositETH(address indexed user, uint256 amount);
    event WithdrawETH(address indexed user, uint256 amount);
    event DepositToken(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event WithdrawToken(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    event WrapETH(address indexed user, uint256 amount);
    event UnwrapWETH(address indexed user, uint256 amount);

    error Vault__InsufficientETHBalance(uint available, uint required);
    error Vault__InsufficientTokenBalance(uint available, uint required);
    error Vault__MustDepositMoreThanZero();
    error Vault__TransferFailed();

    constructor(address _weth) {
        WETH = _weth;
    }

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable {
        if (msg.value == 0) {
            revert Vault__MustDepositMoreThanZero();
        }
        ethBalances[msg.sender] += msg.value;
        emit DepositETH(msg.sender, msg.value);
    }

    function withdrawETH(uint256 amount) public {
        uint balance = ethBalances[msg.sender];
        if (balance < amount) {
            revert Vault__InsufficientETHBalance(balance, amount);
        }
        ethBalances[msg.sender] = balance - amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert Vault__TransferFailed();
        }

        emit WithdrawETH(msg.sender, amount);
    }

    function depositToken(address token, uint256 amount) public {
        if (amount == 0) {
            revert Vault__MustDepositMoreThanZero();
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        tokenBalances[msg.sender][token] += amount;
        emit DepositToken(msg.sender, token, amount);
    }

    function withdrawToken(address token, uint256 amount) public {
        uint balance = tokenBalances[msg.sender][token];
        if (balance < amount) {
            revert Vault__InsufficientTokenBalance(balance, amount);
        }
        tokenBalances[msg.sender][token] = balance - amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, token, amount);
    }

    function wrapETH(uint256 amount) public {
        uint balance = ethBalances[msg.sender];
        if (balance < amount) {
            revert Vault__InsufficientETHBalance(balance, amount);
        }
        ethBalances[msg.sender] = balance - amount;
        IWETH(WETH).deposit{value: amount}();
        tokenBalances[msg.sender][WETH] += amount;
        emit WrapETH(msg.sender, amount);
    }

    function unwrapWETH(uint256 amount) public {
        uint balance = tokenBalances[msg.sender][WETH];
        if (balance < amount) {
            revert Vault__InsufficientTokenBalance(balance, amount);
        }
        tokenBalances[msg.sender][WETH] = balance - amount;
        IWETH(WETH).withdraw(amount);
        ethBalances[msg.sender] += amount;
        emit UnwrapWETH(msg.sender, amount);
    }

    function getETHBalance(address user) external view returns (uint256) {
        return ethBalances[user];
    }

    function getTokenBalance(
        address user,
        address token
    ) external view returns (uint256) {
        return tokenBalances[user][token];
    }
}
