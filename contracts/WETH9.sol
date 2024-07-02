// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    error WETH9__InsufficientBalance(uint available, uint required);
    error WETH9__TransferFailed();
    error WETH9__AllowanceExceeded(uint available, uint required);

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        uint balance = balanceOf[msg.sender];
        if (balance < wad) {
            revert WETH9__InsufficientBalance(balance, wad);
        }
        balanceOf[msg.sender] = balance - wad;

        (bool success, ) = msg.sender.call{value: wad}("");
        if (!success) {
            revert WETH9__TransferFailed();
        }

        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) public returns (bool) {
        uint srcBalance = balanceOf[src];
        if (srcBalance < wad) {
            revert WETH9__InsufficientBalance(srcBalance, wad);
        }

        if (src != msg.sender) {
            uint currentAllowance = allowance[src][msg.sender];
            if (currentAllowance < wad) {
                revert WETH9__AllowanceExceeded(currentAllowance, wad);
            }
            if (currentAllowance != type(uint).max) {
                allowance[src][msg.sender] = currentAllowance - wad;
            }
        }

        balanceOf[src] = srcBalance - wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);
        return true;
    }
}
