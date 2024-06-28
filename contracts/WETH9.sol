// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH9 is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}


    error WETH9__InsufficientBalance(uint256 requested, uint256 available);
    error WETH9__ETHTransferFailed();

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 value) external {
        uint256 balance = balanceOf(msg.sender);
        if (balance < value) {
            revert WETH9__InsufficientBalance({
                requested: value,
                available: balance
            });
        }
        _burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);

        (bool success, ) = msg.sender.call{value: value}("");
        if (!success) {
            revert WETH9__ETHTransferFailed();
        }
    }

    receive() external payable {
        deposit();
    }
}
