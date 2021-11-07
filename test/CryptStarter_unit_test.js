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
    currentIndex = await cryptStarter.currentIndex();
    weekFromNow = moment()
      .tz('UTC')
      .add(7, 'days')
      .set({ hour: 0, minute: 0, seconds: 0 });
  });

  it.skip('Campaign in progress can be funded', async () => {});
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

  it('Shoud fail when deadline is less than 7 days from now', async () => {
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
    const campaignCreatedEvent = receipt.events[0];
    console.log(campaignCreatedEvent);

    expect(campaignCreatedEvent.event).to.equal('CampaignCreated');
    expect(campaignCreatedEvent.args['name']).to.equal(campaignName);
    expect(campaignCreatedEvent.args['owner']).to.equal(signerAddress);

    expect(
      ethers.BigNumber.from(campaignCreatedEvent.args['index']._hex).toString()
    ).to.be.a.bignumber.that.is.equal(
      ethers.BigNumber.from(currentIndex).toString()
    );

    expect(
      ethers.BigNumber.from(campaignCreatedEvent.args['target']._hex).toString()
    ).to.be.a.bignumber.that.is.equal(campaignTarget);

    expect(
      ethers.BigNumber.from(campaignCreatedEvent.args['target']._hex).toString()
    ).to.be.a.bignumber.that.is.equal(campaignTarget);

    expect(
      ethers.BigNumber.from(
        campaignCreatedEvent.args['deadline']._hex
      ).toString()
    ).to.be.a.bignumber.that.is.equal(weekFromNow.unix().toString());
  });

  it('Creates campaign successfully', async () => {
    const currentNumberOfCampaigns = currentIndex;
    await cryptStarter.createCampaign(
      campaignName,
      campaignTarget,
      weekFromNow.unix()
    );

    let campaign = await cryptStarter.campaigns(0);
    const newNumberOfCampaigns = await cryptStarter.currentIndex();

    expect(campaign['owner']).to.equal(signerAddress);
    expect(campaign['name']).to.equal(campaignName);

    expect(
      ethers.BigNumber.from(campaign['target']._hex).toString()
    ).to.be.a.bignumber.that.is.equal(campaignTarget);

    expect(
      ethers.BigNumber.from(campaign['deadline']._hex).toString()
    ).to.be.a.bignumber.that.is.equal(weekFromNow.unix().toString());

    expect(
      ethers.BigNumber.from(campaign['totalRaised']._hex).toString()
    ).to.be.a.bignumber.that.is.equal('0');

    expect(campaign['status']).to.equal(0);

    expect(
      ethers.BigNumber.from(newNumberOfCampaigns._hex).toString()
    ).to.be.a.bignumber.that.is.equal(
      ethers.BigNumber.from(currentNumberOfCampaigns).add(1).toString()
    );
  });
});