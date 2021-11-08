//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol';

contract CryptStarter is KeeperCompatibleInterface {
  // Enums
  enum CampaignStatus {
    InProgress,
    Successful,
    Unsuccessful,
    Withdrawn
  }

  // Structs
  struct Backer {
    address backerAddress;
    uint256 amount;
  }

  struct Campaign {
    address owner;
    string name;
    uint256 target;
    uint256 deadline;
    uint256 totalRaised;
    CampaignStatus status;
    mapping(address => uint256) backersAmounts;
    mapping(address => bool) backersAllowances;
    Backer[] backers;
  }

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
      campaigns[_index].owner != address(0),
      "Campaign with the given index wasn't registered"
    );
    _;
  }

  modifier campaignInProgress(uint256 _index) {
    require(
      campaigns[_index].status == CampaignStatus.InProgress,
      'Campaign is not in progress'
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

  modifier hasFundsInCampaign(uint256 _index) {
    require(
      campaigns[_index].backersAmounts[msg.sender] > 0,
      'You have no funds locked in this campaign'
    );
    _;
  }

  modifier isAllowedToWithdrawFunds(uint256 _index) {
    require(
      campaigns[_index].backersAllowances[msg.sender] == true,
      'You are (no longer) allowed to withdraw funds from this campaign'
    );
    _;
  }

  modifier readyToWithdraw(uint256 _index) {
    require(
      campaigns[_index].status == CampaignStatus.Successful,
      'Funds are not ready to withdraw yet'
    );
    _;
  }

  modifier hasCampaignFailed(uint256 _index) {
    require(
      campaigns[_index].status == CampaignStatus.Unsuccessful,
      'Campaign is either still in progress or had reached it goal'
    );
    _;
  }
  uint256 public currentIndex;

  uint256 public lastKeeperCheck;

  mapping(uint256 => Campaign) public campaigns;

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
    for (uint8 i = 0; i < currentIndex; i++) {
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

  function createCampaign(
    string memory _name,
    uint256 _target,
    uint256 _deadline
  ) public {
    require(
      (calculateStartOfDayForTimestamp(block.timestamp) + 604800) <= _deadline,
      'Minimum deadline for a campain is 7 days'
    );
    Campaign storage campaign = campaigns[currentIndex];
    campaign.owner = address(msg.sender);
    campaign.name = _name;
    campaign.target = _target;
    campaign.deadline = _deadline;
    campaign.totalRaised = 0;
    campaign.status = CampaignStatus.InProgress;

    emit CampaignCreated(currentIndex, msg.sender, _name, _target, _deadline);

    ownersCampaigns[msg.sender]++;
    currentIndex++;
  }

  function fundCampaign(uint256 _index)
    public
    payable
    campaignExists(_index)
    campaignInProgress(_index)
  {
    Backer backer = Backer(msg.sender, msg.value);
    Campaign storage campaign = campaigns[_index];
    campaign.backers.push(backer);
    campaign.backersAmounts[msg.sender] += msg.value;
    campaign.backersAllowances[msg.sender] = true;
    campaign.totalRaised = msg.value;

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
    isAllowedToWithdrawFunds(_index)
  {
    Campaign storage campaign = campaigns[_index];
    campaign.backersAllowances[msg.sender] = false;
    payable(msg.sender).transfer(campaign.backersAmounts[msg.sender]);
    emit UnsuccessfulCampaignFundsWithdrawn(
      _index,
      msg.sender,
      campaign.backersAmounts[msg.sender]
    );
  }
}
