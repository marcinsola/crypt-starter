//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CryptStarter {
    // Enums
    enum CampaignStatus {
        InProgress,
        Completed,
        Unsuccessful,
        Withdrawn
    }

    // Structs
    struct Campaign {
        address owner;
        string name;
        uint256 target;
        uint256 deadline;
        uint256 totalRaised;
        CampaignStatus status;
        mapping(address => uint256) supporters;
    }

    // Events
    event CampaignCreated(
        uint256 index,
        address owner,
        string name,
        uint256 target,
        uint256 deadline
    );

    event CampaignFunded(uint256 index, address supporter, uint256 amount);

    event CampaignFundsClaimed(uint256 index, address owner, uint256 amount);

    // Modifiers
    modifier campaignExists(uint256 _index) {
        require(
            campaigns[_index].owner != address(0),
            "Campaign with the given index wasn't regitered"
        );
        _;
    }

    modifier isCampaignOwner(uint256 _index) {
        require(
            campaigns[_index].owner == msg.sender,
            "You're not the author of this campaign"
        );
        _;
    }

    modifier readyToWithdraw(uint256 _index) {
        require(
            ((block.timestamp >= campaigns[_index].deadline) &&
                (campaigns[_index].target >= campaigns[_index].totalRaised) &&
                (campaigns[_index].status == CampaignStatus.Completed)),
                "Funds are not ready to withdraw yet"
        );
        _;
    }

    uint256 public currentIndex;

    mapping(uint256 => Campaign) public campaigns;

    mapping(address => uint256) public ownersCampaigns;

    function createCampaign(
        string calldata _name,
        uint256 _target,
        uint256 _deadline
    ) public {
        Campaign storage campaign = campaigns[currentIndex];
        campaign.owner = address(msg.sender);
        campaign.name = _name;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.totalRaised = 0;
        campaign.status = CampaignStatus.InProgress;

        emit CampaignCreated(
            currentIndex,
            msg.sender,
            _name,
            _target,
            _deadline
        );

        ownersCampaigns[msg.sender]++;
        currentIndex++;
    }

    function getCampaign(uint256 _index)
        public
        view
        returns (
            address owner,
            string memory name,
            uint256 target,
            uint256 deadline,
            uint256 status
        )
    {
        Campaign storage campaign = campaigns[_index];

        return (
            campaign.owner,
            campaign.name,
            campaign.target,
            campaign.deadline,
            uint256(campaign.status)
        );
    }

    function fundCampaign(uint256 _index)
        public
        payable
        campaignExists(_index)
    {
        campaigns[_index].supporters[msg.sender] += msg.value;
        emit CampaignFunded(_index, msg.sender, msg.value);
    }

    function claimSuccessfulCampaignFunds(uint256 _index)
        public
        campaignExists(_index)
        isCampaignOwner(_index)
        readyToWithdraw(_index)
    {
        Campaign storage campaign = campaigns[_index];
        campaign.status = CampaignStatus.Withdrawn;
        emit CampaignFundsClaimed(_index, msg.sender, campaign.totalRaised);
        payable(msg.sender).transfer(campaign.totalRaised);
    }
}
