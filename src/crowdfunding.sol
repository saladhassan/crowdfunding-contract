// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract crowdfunding {
    // ------------------
    // SECURITY GUARD
    // ------------------
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    // ----------------------
    // CAMPAIGN STATE MACHINE
    // ----------------------
    enum CampaignStatus {
        Active,
        Successful,
        Failed
    }

    // ------------------------
    // STRUCT
    // ------------------------
    struct CampaignData {
        address payable owner;
        uint256 goal;
        uint256 totalRaised;
        uint256 deadline;
        bool withdrawn;
        string title;
        CampaignStatus status;
    }

    // -----------------------
    // STATE VARIABLES
    // -----------------------
    uint256 public campaignCount;

    mapping(uint256 => CampaignData) public campaigns;

    mapping(uint256 => mapping(address => uint256)) public donations;

    // -------------------------
    // EVENTS
    // -------------------------
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed owner,
        uint256 goal,
        uint256 deadline,
        string title
    );

    event Donated(
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount
    );

    event Withdraw(
        uint256 indexed campaignId,
        address indexed owner,
        uint256 amount
    );

    event Refund(
        uint256 indexed campaignId,
        address indexed user,
        uint256 amount
    );

    // -----------------------
    // CREATE CAMPAIGN
    // -----------------------
    function createCampaign(
        uint256 _goal,
        uint256 _duration,
        string memory _title
    ) public {
        campaignCount++;
        uint256 campaignId = campaignCount;

        campaigns[campaignId] = CampaignData({
            owner: payable(msg.sender),
            goal: _goal,
            totalRaised: 0,
            deadline: block.timestamp + _duration,
            withdrawn: false,
            title: _title,
            status: CampaignStatus.Active
        });

        emit CampaignCreated(
            campaignId,
            msg.sender,
            _goal,
            block.timestamp + _duration,
            _title
        );
    }

    // -----------------------
    // DONATE
    // -----------------------
    function donate(uint256 _campaignId) public payable nonReentrant {
        CampaignData storage campaign = campaigns[_campaignId];

        require(campaign.owner != address(0), "Campaign does not exist");
        require(campaign.status == CampaignStatus.Active, "Not active");
        require(block.timestamp < campaign.deadline, "Campaign ended");
        require(msg.value > 0, "Invalid amount");

        donations[_campaignId][msg.sender] += msg.value;
        campaign.totalRaised += msg.value;

        emit Donated(_campaignId, msg.sender, msg.value);
    }

    // --------------------------
    // WITHDRAW
    // --------------------------
    function withdraw(uint256 _campaignId) public nonReentrant {
        CampaignData storage campaign = campaigns[_campaignId];

        require(campaign.owner != address(0), "Campaign does not exist");
        require(msg.sender == campaign.owner, "Not owner");
        require(block.timestamp > campaign.deadline, "Deadline not reached");
        require(campaign.totalRaised >= campaign.goal, "Goal not reached");
        require(!campaign.withdrawn, "Already withdrawn");

        campaign.withdrawn = true;
        campaign.status = CampaignStatus.Successful;

        uint256 amount = campaign.totalRaised;

        (bool success, ) = campaign.owner.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(_campaignId, campaign.owner, amount);
    }

    // ----------------------
    // REFUND
    // ----------------------
    function refund(uint256 _campaignId) public nonReentrant {
        CampaignData storage campaign = campaigns[_campaignId];

        require(campaign.owner != address(0), "Campaign does not exist");
        require(block.timestamp > campaign.deadline, "Deadline not reached");
        require(campaign.totalRaised < campaign.goal, "Goal was reached");
        require(
            campaign.status != CampaignStatus.Successful,
            "Campaign succeeded"
        );

        uint256 amount = donations[_campaignId][msg.sender];
        require(amount > 0, "No amount to refund");

        donations[_campaignId][msg.sender] = 0;
        campaign.totalRaised -= amount;

        campaign.status = CampaignStatus.Failed;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");

        emit Refund(_campaignId, msg.sender, amount);
    }
}
