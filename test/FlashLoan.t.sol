// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FlashLoan} from "../src/FlashLoan.sol";
import {IERC20} from "@aave/core-v3/dependencies/openzeppelin/contracts/IERC20.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/interfaces/IPool.sol";

contract FlashLoanTest is Test {
    FlashLoan public flashLoan;
    address public owner;
    address public user;

    // Sepolia Aave v3 addresses
    address constant POOL_ADDRESSES_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
    address constant DAI = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;
    address constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;

    function setUp() public {
        // Fork Sepolia for testing with real Aave contracts
        string memory SEPOLIA_RPC_URL = vm.envOr("SEPOLIA_RPC_URL", string("https://eth-sepolia.g.alchemy.com/v2/your-api-key"));

        // Only fork if RPC URL is properly configured
        if (bytes(SEPOLIA_RPC_URL).length > 0 && !_isDefaultRpcUrl(SEPOLIA_RPC_URL)) {
            vm.createSelectFork(SEPOLIA_RPC_URL);
        }

        owner = address(this);
        user = makeAddr("user");

        flashLoan = new FlashLoan(POOL_ADDRESSES_PROVIDER);

        vm.label(address(flashLoan), "FlashLoan");
        vm.label(DAI, "DAI");
        vm.label(USDC, "USDC");
    }

    function _isDefaultRpcUrl(string memory url) internal pure returns (bool) {
        return keccak256(bytes(url)) == keccak256(bytes("https://eth-sepolia.g.alchemy.com/v2/your-api-key"));
    }

    // Test contract deployment
    function test_Deployment() public view {
        assertEq(flashLoan.s_owner(), owner);
    }

    // Test owner is set correctly
    function test_OwnerIsSetCorrectly() public view {
        assertEq(flashLoan.s_owner(), owner);
    }

    // Test flash loan request (will revert without sufficient liquidity in test)
    function test_RequestFlashLoan_RevertsWithoutLiquidity() public {
        // This should revert because the contract doesn't have funds to repay
        vm.expectRevert();
        flashLoan.requestFlashLoan(DAI, 1000e18);
    }

    // Test getBalance function
    function test_GetBalance() public {
        assertEq(flashLoan.getBalance(DAI), 0);

        // Deal some DAI to the contract
        deal(DAI, address(flashLoan), 100e18);

        assertEq(flashLoan.getBalance(DAI), 100e18);
    }

    // Test withdraw function - only owner
    function test_Withdraw_OnlyOwner() public {
        // Deal some DAI to the contract
        deal(DAI, address(flashLoan), 100e18);

        // Try to withdraw as non-owner
        vm.prank(user);
        vm.expectRevert("Only s_owner can call this function");
        flashLoan.withdraw(DAI);

        // Withdraw as owner should succeed
        uint256 balanceBefore = IERC20(DAI).balanceOf(owner);
        flashLoan.withdraw(DAI);
        uint256 balanceAfter = IERC20(DAI).balanceOf(owner);

        assertEq(balanceAfter - balanceBefore, 100e18);
        assertEq(flashLoan.getBalance(DAI), 0);
    }

    // Test withdraw function - success
    function test_Withdraw_Success() public {
        // Deal some DAI to the contract
        deal(DAI, address(flashLoan), 100e18);

        uint256 balanceBefore = IERC20(DAI).balanceOf(owner);
        flashLoan.withdraw(DAI);
        uint256 balanceAfter = IERC20(DAI).balanceOf(owner);

        assertEq(balanceAfter - balanceBefore, 100e18);
    }

    // Test receive function
    function test_ReceiveEther() public {
        uint256 amount = 1 ether;

        (bool success,) = address(flashLoan).call{value: amount}("");
        assertTrue(success);
        assertEq(address(flashLoan).balance, amount);
    }

    // Test multiple withdrawals
    function test_MultipleWithdrawals() public {
        // Deal some tokens to the contract
        deal(DAI, address(flashLoan), 100e18);
        deal(USDC, address(flashLoan), 50e6);

        // Withdraw DAI
        flashLoan.withdraw(DAI);
        assertEq(flashLoan.getBalance(DAI), 0);

        // Withdraw USDC
        flashLoan.withdraw(USDC);
        assertEq(flashLoan.getBalance(USDC), 0);
    }

    // Fuzz test: withdraw various amounts
    function testFuzz_Withdraw(uint256 amount) public {
        amount = bound(amount, 1, 1000000e18);

        deal(DAI, address(flashLoan), amount);

        uint256 balanceBefore = IERC20(DAI).balanceOf(owner);
        flashLoan.withdraw(DAI);
        uint256 balanceAfter = IERC20(DAI).balanceOf(owner);

        assertEq(balanceAfter - balanceBefore, amount);
        assertEq(flashLoan.getBalance(DAI), 0);
    }
}

// Integration test contract for testing with actual flash loan execution
contract FlashLoanIntegrationTest is Test {
    FlashLoan public flashLoan;
    address public owner;

    // Sepolia Aave v3 addresses
    address constant POOL_ADDRESSES_PROVIDER = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
    address constant DAI = 0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357;

    function setUp() public {
        // Fork Sepolia for integration testing
        string memory SEPOLIA_RPC_URL = vm.envOr("SEPOLIA_RPC_URL", string(""));

        // Skip if no RPC URL is configured
        if (bytes(SEPOLIA_RPC_URL).length == 0) {
            vm.skip(true);
            return;
        }

        vm.createSelectFork(SEPOLIA_RPC_URL);

        owner = address(this);
        flashLoan = new FlashLoan(POOL_ADDRESSES_PROVIDER);

        vm.label(address(flashLoan), "FlashLoan");
        vm.label(DAI, "DAI");
    }

    // Test successful flash loan with repayment
    function test_FlashLoanWithRepayment() public {
        // Deal some DAI to the contract to pay the premium
        deal(DAI, address(flashLoan), 1e18);

        uint256 loanAmount = 100e18;

        // Get pool address
        IPoolAddressesProvider provider = IPoolAddressesProvider(POOL_ADDRESSES_PROVIDER);
        address pool = provider.getPool();

        // Check if pool has enough liquidity
        uint256 poolBalance = IERC20(DAI).balanceOf(pool);
        if (poolBalance < loanAmount) {
            vm.skip(true);
            return;
        }

        // Request flash loan
        flashLoan.requestFlashLoan(DAI, loanAmount);

        // The flash loan should complete successfully
        // The contract should have less balance due to premium payment
        assertTrue(flashLoan.getBalance(DAI) < 1e18);
    }
}
