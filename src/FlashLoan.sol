// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/dependencies/openzeppelin/contracts/IERC20.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase {
    address payable s_owner;

    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        s_owner = payable(msg.sender);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address, /*initiator*/
        bytes calldata /*params*/
    ) external override returns (bool) {
        // we have borrowed the funds, we need to pay them back
        //logic
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);
        return true;
    }

    function requestFlashLoan(address _asset, uint256 _amount) public {
        POOL.flashLoanSimple(address(this), _asset, _amount, "", 0);
    }

    function getBalance(address _asset) public view returns (uint256) {
        return IERC20(_asset).balanceOf(address(this));
    }

    function withdraw(address _asset) public onlyOwner {
        uint256 amount = getBalance(_asset);
        bool result = IERC20(_asset).transfer(s_owner, amount);
        require(result, "Transfer failed");
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Only s_owner can call this function");
        _;
    }

    receive() external payable {}
}
