//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CryptStarter {
    uint256 public currentIndex;

    enum CampaignStatus {
        Created,
        InProgress,
        Completed,
        Withdrawn
    }

    struct Campaign {
        address owner;
        string name;
        uint256 target;
        uint256 deadline;
        CampaignStatus status;
        mapping(address => uint256) supporters;
    }

    event CampaignCreated(
        uint256 index,
        address owner,
        string name,
        uint256 target,
        uint256 deadline
    );

    event CampaignFunded(uint256 index, address supporter, uint256 amount);

    mapping(uint256 => Campaign) public campaigns;

    mapping(address => uint256) public ownersCampaigns;

    modifier campaignExists(uint256 _index) {
        require(
            campaigns[_index].owner != address(0),
            "Campaign with the given index wasn't regitered"
        );
        _;
    }

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
        campaign.status = CampaignStatus.Created;

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
}
