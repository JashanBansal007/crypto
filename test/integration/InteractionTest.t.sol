// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract InteractionsTest is ZkSyncChainChecker, StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    // uint256 public constant SEND_VALUE = 1e18;
    // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // uint256 public constant SEND_VALUE = 1000000000000000000;

    function setUp() external skipZkSync {
        if (!isZkSyncChain()) {
            DeployFundMe deployer = new DeployFundMe();
            (fundMe, helperConfig) = deployer.deployFundMe();
        } else {
            helperConfig = new HelperConfig();
            fundMe = new FundMe(helperConfig.getConfigByChainId(block.chainid).priceFeed);
        }
        vm.deal(USER, STARTING_USER_BALANCE);
    }

   function testUserCanFundAndOwnerWithdraw() public skipZkSync {
    uint256 preUserBalance = address(USER).balance;
    uint256 preOwnerBalance = address(fundMe.getOwner()).balance;

    // Simulate USER funding the contract
    vm.prank(USER);
    fundMe.fund{value: SEND_VALUE}();

    // Simulate the owner withdrawing funds
    address owner = fundMe.getOwner();
    vm.prank(owner); // Ensure the withdrawal is initiated by the contract owner
    WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
    withdrawFundMe.withdrawFundMe(address(fundMe));

    uint256 afterUserBalance = address(USER).balance;
    uint256 afterOwnerBalance = address(fundMe.getOwner()).balance;

    // Assert all expected conditions
    assert(address(fundMe).balance == 0); // Ensure contract balance is zero
    assertEq(afterUserBalance + SEND_VALUE, preUserBalance); // Ensure USER's balance reflects the SEND_VALUE
    assertEq(preOwnerBalance + SEND_VALUE, afterOwnerBalance); // Ensure owner's balance reflects the withdrawal
}
}