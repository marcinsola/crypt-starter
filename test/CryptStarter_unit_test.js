const moment = require('moment-timezone');
const { expect } = require('chai');
const { ethers } = require('hardhat');

const chai = require('chai');
const BN = require('bn.js');
chai.use(require('chai-bn')(BN));

describe('CryptStarter', () => {
  let cryptStarter,
    campaignName,
    campaignTarget,
    weekFromNow,
    currentIndex,
    signerAddress;

  before(async () => {
    const CryptStarter = await ethers.getContractFactory('CryptStarter');
    cryptStarter = await CryptStarter.deploy();
    await cryptStarter.deployed();
    campaignName = 'TestCampaign';
    campaignTarget = '1000000000000000000';
    const signer = await ethers.getSigner();
    signerAddress = signer.address;
  });

  beforeEach(async () => {
    weekFromNow = moment()
      .tz('UTC')
      .add(7, 'days')
      .set({ hour: 0, minute: 0, seconds: 0 });
  });

  it.skip('Campaign cannot be funded if is not in progress', async () => {});
  it.skip('Campaign owner can claim fund from successful campaign', async () => {});
  it.skip('Campaign owner cannot claim fund from campaign if status is different than in progress', async () => {});
  it.skip('Only campaign owner can claim funds');
  it.skip('Cannot claim funds from non-existent campaign');
  it.skip('CampaignFundsClaimed emitted upon campaign funding');

  it.skip('Backers can withdraw funds from unsuccessful campaign');
  it.skip('Backers cannot withdraw funds in any other scenario');
  it.skip('Each backer can withdraw funds only once');
  it.skip(
    'UnsuccessfulCampaignFundsWithdrawn emmited upon funds withdrawal by backer'
  );

  it.skip('Shoud fail when deadline is less than 7 days from now', async () => {
    await expect(
      cryptStarter.createCampaign(
        campaignName,
        campaignTarget,
        weekFromNow.subtract(1, 'second').unix()
      )
    ).to.be.revertedWith('Minimum deadline for a campain is 7 days');
  });

  it('Emits CampaignCreated event upon creation', async () => {
    let transaction = await cryptStarter.createCampaign(
      campaignName,
      campaignTarget,
      weekFromNow.unix()
    );
    let receipt = await transaction.wait();
    const campaign = await cryptStarter.campaigns(0);
    const [campaignCreatedEvent] = receipt.events;

    expect(campaignCreatedEvent.event).to.equal('CampaignCreated');
    expect(campaignCreatedEvent.args['owner']).to.equal(signerAddress);
    expect(campaignCreatedEvent.args['name']).to.equal(campaignName);

    expect(
      ethers.BigNumber.from(campaignCreatedEvent.args['index']._hex)
    ).to.equal(0);

    expect(
      ethers.BigNumber.from(campaignCreatedEvent.args['target']._hex)
    ).to.equal(campaignTarget);

    expect(
      ethers.BigNumber.from(campaignCreatedEvent.args['deadline']._hex)
    ).to.equal(weekFromNow.unix());
  });

  it('Creates campaign successfully', async () => {
    const currentNumberOfCampaigns = await cryptStarter.getNumberOfCampaigns();
    await cryptStarter.createCampaign(
      campaignName,
      campaignTarget,
      weekFromNow.unix()
    );

    let campaign = await cryptStarter.campaigns(0);
    const newNumberOfCampaigns = await cryptStarter.getNumberOfCampaigns();

    expect(campaign['owner']).to.equal(signerAddress);
    expect(campaign['name']).to.equal(campaignName);

    expect(ethers.BigNumber.from(campaign['target']._hex)).to.equal(
      campaignTarget
    );

    expect(ethers.BigNumber.from(campaign['deadline']._hex)).to.equal(
      weekFromNow.unix()
    );

    expect(ethers.BigNumber.from(campaign['totalRaised']._hex)).to.equal(0);

    expect(campaign['status']).to.equal(0);

    expect(ethers.BigNumber.from(newNumberOfCampaigns._hex)).to.equal(
      ethers.BigNumber.from(currentNumberOfCampaigns).add(1)
    );
  });

  it('Campaign in progress can be funded', async () => {
    const [owner, backer] = await ethers.getSigners();
    await cryptStarter.createCampaign(
      campaignName,
      campaignTarget,
      weekFromNow.unix()
    );

    const numberOfCampaigns = await cryptStarter.getNumberOfCampaigns();
    currentIndex = numberOfCampaigns - 1;
    const amount = ethers.utils.parseEther('0.1');

    await cryptStarter.connect(backer).fundCampaign(currentIndex, {
      value: amount,
    });

    const campaign = await cryptStarter.campaigns(currentIndex);
    const donation = await cryptStarter.campaignDonations(currentIndex, 0);
    const backerAmount = await cryptStarter.campaignDonationsByBackerAddress(
      currentIndex,
      backer.address
    );

    expect(ethers.BigNumber.from(campaign.totalRaised._hex)).to.equal(amount);
    expect(ethers.BigNumber.from(backerAmount._hex)).to.equal(amount);
    expect(campaign.totalDonations).to.equal(1);
    expect(donation.backerAddress).to.equal(backer.address);
    expect(donation.amount).to.equal(amount);
  });

  it.skip('backersAmounts is calculated correctly');
  it('Campaign cannot be backed by the owner', async () => {
    await cryptStarter.createCampaign(
      campaignName,
      campaignTarget,
      weekFromNow.unix()
    );

    await expect(
      cryptStarter.fundCampaign(currentIndex, {
        value: ethers.utils.parseEther('0.1'),
      })
    ).to.be.revertedWith('You cannot fund your own campaign');
  });
});
