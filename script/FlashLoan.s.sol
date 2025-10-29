// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FlashLoan} from "../src/FlashLoan.sol";

contract FlashLoanScript is Script {
    FlashLoan public flashLoan;

    // Network configurations for Aave v3 Pool Addresses Provider
    mapping(uint256 => address) public poolAddressesProviders;

    function setUp() public {
        // Mainnet
        poolAddressesProviders[1] = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;

        // Sepolia
        poolAddressesProviders[11155111] = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;

        // Polygon
        poolAddressesProviders[137] = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

        // Arbitrum
        poolAddressesProviders[42161] = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

        // Optimism
        poolAddressesProviders[10] = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;

        // Avalanche
        poolAddressesProviders[43114] = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 chainId = block.chainid;

        address poolAddressesProvider = poolAddressesProviders[chainId];

        require(poolAddressesProvider != address(0), "Unsupported network");

        console.log("Deploying FlashLoan contract on chain ID:", chainId);
        console.log("Using Pool Addresses Provider:", poolAddressesProvider);

        vm.startBroadcast(deployerPrivateKey);

        flashLoan = new FlashLoan(poolAddressesProvider);

        vm.stopBroadcast();

        console.log("FlashLoan deployed at:", address(flashLoan));
        console.log("Owner:", flashLoan.s_owner());
    }

    // Helper function to deploy with custom provider address
    function runWithCustomProvider(address _poolAddressesProvider) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying FlashLoan contract with custom provider");
        console.log("Using Pool Addresses Provider:", _poolAddressesProvider);

        vm.startBroadcast(deployerPrivateKey);

        flashLoan = new FlashLoan(_poolAddressesProvider);

        vm.stopBroadcast();

        console.log("FlashLoan deployed at:", address(flashLoan));
        console.log("Owner:", flashLoan.s_owner());
    }
}
