// SPDX-License-Identifier:
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/crowdfunding.sol";

contract crowdfundingTest is Test {
    crowdfunding fund;

    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        fund = new crowdfunding();
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    receive() external payable {}

    function testCreateCampaignWorks() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        (
            address owner,
            uint256 goal,
            uint256 totalRaised,
            uint256 deadline,
            bool withdrawn,
            string memory title,
            crowdfunding.CampaignStatus status
        ) = fund.campaigns(1);

        assertEq(fund.campaignCount(), 1);

        assertEq(owner, address(this));
        assertEq(goal, 5 ether);
        assertEq(totalRaised, 0);
        assertEq(withdrawn, false);
        assertEq(title, "Help Children");

        assertEq(uint256(status), 0);
    }

    function testDonateWorks() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);

        fund.donate{value: 1 ether}(1);

        assertEq(fund.donations(1, user1), 1 ether);

        (, , uint256 totalRaised, , , , ) = fund.campaigns(1);

        assertEq(totalRaised, 1 ether);
    }

    function testCannotDonateZero() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");
        vm.prank(user1);
        vm.expectRevert();
        fund.donate{value: 0}(1);
    }

    function testCannotDonateAfterDeadline() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");
        vm.warp(block.timestamp + 8 days);
        vm.prank(user1);
        vm.expectRevert();
        fund.donate{value: 1 ether}(1);
    }

    function testCannotDonateInvalidCampaign() public {
        vm.prank(user1);
        vm.expectRevert();
        fund.donate{value: 1 ether}(1);
    }

    function testWithdrawWorks() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);

        fund.donate{value: 5 ether}(1);

        vm.warp(block.timestamp + 8 days);

        uint256 ownerBefore = address(this).balance;

        fund.withdraw(1);

        uint256 ownerAfter = address(this).balance;

        assertGt(ownerAfter, ownerBefore);

        (, , , , bool withdrawn, , crowdfunding.CampaignStatus status) = fund
            .campaigns(1);

        assertEq(withdrawn, true);

        assertEq(uint256(status), 1);
    }

    function testOnlyOwnerCanWithdraw() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);

        fund.donate{value: 5 ether}(1);

        vm.warp(block.timestamp + 8 days);

        vm.prank(user1);

        vm.expectRevert();

        fund.withdraw(1);
    }

    function testCannotWithdrawBeforeDeadline() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);
        fund.donate{value: 5 ether}(1);

        vm.prank(address(this));
        vm.expectRevert();

        fund.withdraw(1);
    }

    function testCannotWithdrawIfGoalNotReached() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);
        fund.donate{value: 1 ether}(1);

        vm.warp(block.timestamp + 8 days);

        vm.prank(address(this));
        vm.expectRevert();

        fund.withdraw(1);
    }

    function testRefundWorks() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);
        fund.donate{value: 1 ether}(1);

        vm.warp(block.timestamp + 8 days);

        uint256 userBefore = user1.balance;

        vm.prank(user1);
        fund.refund(1);

        uint256 userAfter = user1.balance;

        assertGt(userAfter, userBefore);

        assertEq(fund.donations(1, user1), 0);
    }

    function testCannotRefundBeforeDeadline() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");
        vm.prank(user1);
        fund.donate{value: 5 ether}(1);
        vm.prank(user1);
        vm.expectRevert();

        fund.refund(1);
    }

    function testCannotRefundAfterSuccess() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);
        fund.donate{value: 5 ether}(1);

        vm.warp(block.timestamp + 8 days);

        fund.withdraw(1);

        vm.prank(user1);
        vm.expectRevert();

        fund.refund(1);
    }

    function testNonDonorCannotRefund() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);
        fund.donate{value: 1 ether}(1);

        vm.warp(block.timestamp + 8 days);

        vm.prank(user2);
        vm.expectRevert();

        fund.refund(1);
    }

    function testMultipleDonationsAccumulate() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");

        vm.prank(user1);
        fund.donate{value: 1 ether}(1);

        vm.prank(user2);
        fund.donate{value: 2 ether}(1);

        (, , uint256 totalRaised, , , , ) = fund.campaigns(1);

        assertEq(totalRaised, 3 ether);
    }

    function testCampaignCountIncreases() public {
        fund.createCampaign(5 ether, 7 days, "Help Children");
        fund.createCampaign(10 ether, 3 days, "School Project");

        assertEq(fund.campaignCount(), 2);
    }

    function testDonateInvalidCampaignFails() public {
        vm.prank(user1);
        vm.expectRevert();

        fund.donate{value: 1 ether}(99);
    }
}
