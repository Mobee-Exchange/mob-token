// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MobToken} from "../src/MobToken.sol";

contract MobTokenTest is Test {
    MobToken public token;

    address public owner;
    address public user1;
    address public user2;

    string constant TOKEN_NAME = "Mobee Token";
    string constant TOKEN_SYMBOL = "MOB";
    uint256 constant INITIAL_SUPPLY = 500_000_000; // 500 million tokens
    uint256 constant INITIAL_SUPPLY_WITH_DECIMALS = INITIAL_SUPPLY * 10 ** 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        token = new MobToken(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
    }

    // Constructor Tests
    function test_Constructor_SetsCorrectName() public {
        assertEq(token.name(), TOKEN_NAME);
    }

    function test_Constructor_SetsCorrectSymbol() public {
        assertEq(token.symbol(), TOKEN_SYMBOL);
    }

    function test_Constructor_SetsCorrectDecimals() public {
        assertEq(token.decimals(), 18);
    }

    function test_Constructor_MintsCorrectInitialSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY_WITH_DECIMALS);
    }

    function test_Constructor_MintsToDeployer() public {
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY_WITH_DECIMALS);
    }

    function test_Constructor_EmitsTransferEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), owner, INITIAL_SUPPLY_WITH_DECIMALS);

        new MobToken(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY);
    }

    // Edge case constructor tests
    function test_Constructor_WithZeroSupply() public {
        MobToken zeroToken = new MobToken("Zero", "ZERO", 0);
        assertEq(zeroToken.totalSupply(), 0);
        assertEq(zeroToken.balanceOf(address(this)), 0);
    }

    function test_Constructor_WithLargeSupply() public {
        uint256 largeSupply = type(uint256).max / 10 ** 18; // Max possible without overflow
        MobToken largeToken = new MobToken("Large", "LARGE", largeSupply);
        assertEq(largeToken.totalSupply(), largeSupply * 10 ** 18);
        assertEq(largeToken.balanceOf(address(this)), largeSupply * 10 ** 18);
    }

    function test_Constructor_WithEmptyStrings() public {
        MobToken emptyToken = new MobToken("", "", 1000);
        assertEq(emptyToken.name(), "");
        assertEq(emptyToken.symbol(), "");
        assertEq(emptyToken.totalSupply(), 1000 * 10 ** 18);
    }

    // Transfer Tests
    function test_Transfer_Success() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, transferAmount);

        bool success = token.transfer(user1, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY_WITH_DECIMALS - transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
    }

    function test_Transfer_InsufficientBalance() public {
        vm.expectRevert();
        token.transfer(user1, INITIAL_SUPPLY_WITH_DECIMALS + 1);
    }

    function test_Transfer_ToZeroAddress() public {
        vm.expectRevert();
        token.transfer(address(0), 1000);
    }

    function test_Transfer_ZeroAmount() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user1, 0);

        bool success = token.transfer(user1, 0);
        assertTrue(success);
        assertEq(token.balanceOf(user1), 0);
    }

    // TransferFrom Tests
    function test_TransferFrom_Success() public {
        uint256 transferAmount = 1000 * 10 ** 18;
        uint256 approvalAmount = 2000 * 10 ** 18;

        // First approve user1 to spend tokens
        token.approve(user1, approvalAmount);

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, user2, transferAmount);

        bool success = token.transferFrom(owner, user2, transferAmount);

        assertTrue(success);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY_WITH_DECIMALS - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(owner, user1), approvalAmount - transferAmount);
    }

    function test_TransferFrom_InsufficientAllowance() public {
        uint256 transferAmount = 1000 * 10 ** 18;

        token.approve(user1, transferAmount - 1);

        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(owner, user2, transferAmount);
    }

    function test_TransferFrom_InsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY_WITH_DECIMALS + 1;

        token.approve(user1, transferAmount);

        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(owner, user2, transferAmount);
    }

    // Approval Tests
    function test_Approve_Success() public {
        uint256 approvalAmount = 1000 * 10 ** 18;

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, user1, approvalAmount);

        bool success = token.approve(user1, approvalAmount);

        assertTrue(success);
        assertEq(token.allowance(owner, user1), approvalAmount);
    }

    function test_Approve_ZeroAddress() public {
        vm.expectRevert();
        token.approve(address(0), 1000);
    }

    function test_Approve_OverwriteExistingApproval() public {
        uint256 firstApproval = 1000 * 10 ** 18;
        uint256 secondApproval = 2000 * 10 ** 18;

        token.approve(user1, firstApproval);
        assertEq(token.allowance(owner, user1), firstApproval);

        token.approve(user1, secondApproval);
        assertEq(token.allowance(owner, user1), secondApproval);
    }

    // Fuzz Tests
    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY_WITH_DECIMALS);

        bool success = token.transfer(user1, amount);
        assertTrue(success);
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY_WITH_DECIMALS - amount);
    }

    function testFuzz_Approve(uint256 amount) public {
        bool success = token.approve(user1, amount);
        assertTrue(success);
        assertEq(token.allowance(owner, user1), amount);
    }

    function testFuzz_Constructor(string memory name, string memory symbol, uint256 initialSupply) public {
        // Bound initialSupply to prevent overflow
        initialSupply = bound(initialSupply, 0, type(uint256).max / 10 ** 18);

        MobToken fuzzToken = new MobToken(name, symbol, initialSupply);

        assertEq(fuzzToken.name(), name);
        assertEq(fuzzToken.symbol(), symbol);
        assertEq(fuzzToken.totalSupply(), initialSupply * 10 ** 18);
        assertEq(fuzzToken.balanceOf(address(this)), initialSupply * 10 ** 18);
    }

    // Invariant Tests
    function invariant_TotalSupplyNeverChanges() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY_WITH_DECIMALS);
    }

    // Gas optimization tests
    function test_Gas_Transfer() public {
        uint256 gasBefore = gasleft();
        token.transfer(user1, 1000 * 10 ** 18);
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage for optimization tracking
        console.log("Gas used for transfer:", gasUsed);

        // Reasonable gas limit for a simple transfer
        assertLt(gasUsed, 100000);
    }

    function test_Gas_Approve() public {
        uint256 gasBefore = gasleft();
        token.approve(user1, 1000 * 10 ** 18);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for approve:", gasUsed);
        assertLt(gasUsed, 100000);
    }
}
