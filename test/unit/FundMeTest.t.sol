// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = address(1); // Simulating a user address
    uint256 constant SEND_VALUE = 0.1 ether; // Amount to send during tests
    uint256 constant STARTING_BALANCE   = 10 ether; // Starting balance for the user
    uint256 constant GAS_PRICE = 1; // Gas price for the transaction

    // Add this to your FundMeTest contract
receive() external payable {}

    function setUp() external {
        // Deploy the FundMe contract
        
        DeployFundMe deployFundMe = new DeployFundMe();
        (fundMe, ) = deployFundMe.run();
        vm.deal(USER , STARTING_BALANCE);
        
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsDeployer() public view {
        assertEq(fundMe.getOwner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughETH() public {
        vm.expectRevert(); //hey , the next line should revert
        //asserts(this tx fails/reverts)
        fundMe.fund(); // Call fund() without sending enough ETH
    }

    function testFundUpdatesFundedDataStructure() public {
    // Option 1: Use SEND_VALUE consistently
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();
    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
    
    // OR Option 2: If you want to use 10 ETH
    // vm.deal(USER, 10 ether); // Make sure USER has enough ETH
    // vm.prank(USER);
    // fundMe.fund{value: 10 ether}();
    // uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    // assertEq(amountFunded, 10 ether);
}
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;  
    }

    function testOnlyOwnerCanWithdraw() public funded{
        
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw(); // Only the owner should be able to withdraw
    }

   function testWithDrawWithASingleFunder() public funded {
    // Arrange 
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;

    // Act
    uint256 gasStart = gasleft();
    vm.txGasPrice(GAS_PRICE); // Set the gas price for the transaction
    vm.prank(fundMe.getOwner());
    fundMe.cheaperWithdraw(); // Use the gas-efficient version
    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // Calculate gas used
    
    
    // Assert
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);
}

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders ; i++){
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;    


        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); // Use the gas-efficient version
        vm.stopPrank();


        assert(address(fundMe).balance == 0);
        assert(startingOwnerBalance + startingFundMeBalance == fundMe.getOwner().balance);
         

    }

    function testFundMe() public {
        vm.deal(USER, 1 ether); // Give USER 1 ether for testing
        vm.prank(USER); // Simulate actions as USER
        fundMe.fund{value: SEND_VALUE}();

        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }


}