//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract CryptStarter is KeeperCompatibleInterface {
    // Enums
    enum CampaignStatus {
        InProgress,
        Successful,
        Unsuccessful,
        Withdrawn
    }

    // Structs
    struct Donation {
        address backerAddress;
        uint256 amount;
        uint256 timestamp;
    }

    struct Campaign {
        uint256 index;
        address owner;
        string name;
        uint256 target;
        uint256 deadline;
        uint256 totalRaised;
        uint256 totalDonations;
        CampaignStatus status;
    }

    mapping(uint256 => Donation[]) public campaignDonations;

    mapping(uint256 => mapping(address => uint256))
        public campaignDonationsByBackerAddress;

    // Events
    event CampaignCreated(
        uint256 index,
        address owner,
        string name,
        uint256 target,
        uint256 deadline
    );

    event CampaignFunded(uint256 index, address backer, uint256 amount);

    event CampaignFundsClaimed(uint256 index, address owner, uint256 amount);

    event UnsuccessfulCampaignFundsWithdrawn(
        uint256 index,
        address backer,
        uint256 amount
    );

    // Modifiers
    modifier campaignExists(uint256 _index) {
        require(
            int256(campaigns.length) >= int256(_index) - 1,
            "Campaign with the given index wasn't registered"
        );
        _;
    }

    modifier campaignInProgress(uint256 _index) {
        require(
            campaigns[_index].status == CampaignStatus.InProgress,
            "Campaign is not in progress"
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

    modifier canFundCampaign(uint256 _index) {
        require(
            campaigns[_index].owner != msg.sender,
            "You cannot fund your own campaign"
        );
        _;
    }

    modifier hasFundsInCampaign(uint256 _index) {
        require(
            campaignDonationsByBackerAddress[_index][msg.sender] > 0,
            "You have no funds locked in this campaign"
        );
        _;
    }

    modifier readyToWithdraw(uint256 _index) {
        require(
            campaigns[_index].status == CampaignStatus.Successful,
            "Funds are not ready to withdraw yet"
        );
        _;
    }

    modifier hasCampaignFailed(uint256 _index) {
        require(
            campaigns[_index].status == CampaignStatus.Unsuccessful,
            "Campaign is either still in progress or had reached it goal"
        );
        _;
    }

    uint256 public lastKeeperCheck;

    Campaign[] public campaigns;

    //what to do with it???
    mapping(address => uint256) public ownersCampaigns;

    constructor() {
        lastKeeperCheck = calculateStartOfDayForTimestamp(block.timestamp);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        upkeepNeeded = (block.timestamp >= lastKeeperCheck + 86400);
    }

    function performUpkeep(bytes calldata) external override {
        for (uint256 i = 0; i < campaigns.length; i++) {
            Campaign storage campaign = campaigns[i];
            if (
                campaign.deadline > block.timestamp ||
                campaign.status != CampaignStatus.InProgress
            ) {
                continue;
            }

            if (campaign.totalRaised >= campaign.target) {
                campaign.status = CampaignStatus.Successful;
                continue;
            }

            campaign.status = CampaignStatus.Unsuccessful;
        }

        updateLastKeeperCheck();
    }

    function updateLastKeeperCheck() private {
        lastKeeperCheck = calculateStartOfDayForTimestamp(block.timestamp);
    }

    function calculateStartOfDayForTimestamp(uint256 _timestamp)
        internal
        pure
        returns (uint256)
    {
        // ensures that timestamp is always at midnight
        return _timestamp - (_timestamp % 86400);
    }

    function getCampaignDonations(uint256 _index)
        public
        view
        campaignExists(_index)
        returns (Donation[] memory)
    {
        return campaignDonations[_index];
    }

    function createCampaign(
        string memory _name,
        uint256 _target,
        uint256 _deadline
    ) public {
        require(
            (calculateStartOfDayForTimestamp(block.timestamp) + 604800) <=
                _deadline,
            "Minimum deadline for a campain is 7 days"
        );
        campaigns.push(
            Campaign(
                campaigns.length,
                msg.sender,
                _name,
                _target,
                _deadline,
                0,
                0,
                CampaignStatus.InProgress
            )
        );

        emit CampaignCreated(
            campaigns.length - 1,
            msg.sender,
            _name,
            _target,
            _deadline
        );

        ownersCampaigns[msg.sender]++;
    }

    function fundCampaign(uint256 _index)
        public
        payable
        campaignExists(_index)
        campaignInProgress(_index)
        canFundCampaign(_index)
    {
        Campaign storage campaign = campaigns[_index];
        campaignDonations[_index].push(
            Donation(msg.sender, msg.value, block.timestamp)
        );
        campaign.totalRaised = msg.value;
        campaign.totalDonations++;
        campaignDonationsByBackerAddress[_index][msg.sender] += msg.value;

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
        payable(msg.sender).transfer(campaign.totalRaised);
        emit CampaignFundsClaimed(_index, msg.sender, campaign.totalRaised);
    }

    function withdrawFundsFromUnsuccessfulCampaign(uint256 _index)
        public
        campaignExists(_index)
        hasCampaignFailed(_index)
        hasFundsInCampaign(_index)
    {
        uint256 amountToWithdraw = campaignDonationsByBackerAddress[_index][
            msg.sender
        ];
        campaignDonationsByBackerAddress[_index][msg.sender] = 0;

        payable(msg.sender).transfer(amountToWithdraw);
        emit UnsuccessfulCampaignFundsWithdrawn(
            _index,
            msg.sender,
            amountToWithdraw
        );
    }

    function getNumberOfCampaigns() public view returns (uint256) {
        return campaigns.length;
    }
}
