'use strict';

const util = require('../helper/util');
const VervVluxCrowdsale = artifacts.require('./VervVluxCrowdsale.sol');
const VervVluxToken = artifacts.require('./VervVluxToken.sol');
const TokenVesting = artifacts.require('zeppelin-solidity/contracts/token/ERC20/TokenVesting.sol');

contract('VervVluxCrowdsale', function(accounts) {
	const evm = util.evm(web3);
/*   const addresses = util.accounts(util.isTest() ? accounts : []); */
const addresses = {
	owner: accounts[7],
	companyWallet: accounts[8],
	wallet: accounts[9],
}
	const identity = util.identity(accounts);
	const { Stages, VestingDuration, toWei, fromWei, toTime, toBigNumber, cfg } = util;
	const whitelisted = [];
	const testVesting = { investor: null, contract: null, tokens: null };

	const MAX_PRESALE_CONTRIBUTION_RATE = 8000;
	const MAX_DIST_ERROR_MARGE = 0.1; // meaning 0.1 token error is allowed
	const SEC_3MO = Math.ceil(60 * 60 * 24 * (365 / 4));
	const RATE = '2000';
	const DAY1_RATE = '2100'; // 5% bonus
	const DAY2_RATE = '2050'; // 2.5% bonus
	const START_TIME = toTime('Wednesday, July 4, 2018 4:00:00 PM GMT+00:00');
	const END_TIME = toTime('Saturday, July 7, 2018 4:00:00 PM GMT+00:00');
	const COMPANY_DIST = 30;
	const MAX_END_TIME = 1546344000;

	// add 5 whitelisted participants
	while (whitelisted.length < 5) {
		whitelisted.push(identity.next());
	}

	it('Check initial state', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();

		const tokenAddress = await crowdsale.token.call();
		const token = await VervVluxToken.at(tokenAddress);
		const tokenOwner = await token.owner.call();
		const tokenName = await token.name.call();
		const tokenSymbol = await token.symbol.call();
		const tokenDecimals = await token.decimals.call();
		const tokenMintingFinished = await token.mintingFinished.call();
		const tokenTotalSupply = await token.totalSupply.call();
		const owner = await crowdsale.owner.call();
		const startTime = await crowdsale.startTime.call();
		const endTime = await crowdsale.endTime.call();
		const rate = await crowdsale.rate.call();
		const cap = await crowdsale.cap.call();
		const stage = await crowdsale.stage.call();
		const weiRaised = await crowdsale.weiRaised.call();
		const wallet = await crowdsale.wallet.call();
		const companyWallet = await crowdsale.companyWallet.call();

		assert.equal(owner, addresses.owner, 'Wrong owner address');
		assert.equal(wallet, addresses.wallet, 'Wrong wallet address');
		assert.equal(companyWallet, addresses.companyWallet, 'Wrong company wallet address');
		assert.equal(tokenName, 'Vlux by Verv', 'Wrong token name');
		assert.equal(tokenSymbol, 'VLUX', 'Wrong token symbol');
		assert.equal(tokenDecimals.toString(10), '18', 'Wrong token decimals');
		assert.equal(tokenMintingFinished, false, 'Wrong token minting status');
		assert.equal(tokenOwner, crowdsale.address, 'Wrong token owner');
		assert.equal(startTime.toString(10), START_TIME, 'Wrong start time');
		assert.equal(endTime.toString(10), END_TIME, 'Wrong end time');
		assert.equal(cap.toString(10), toWei(cfg.cap, 'ether'), 'Wrong wei cap');
		assert.equal(stage.toString(10), Stages.PreSale, 'Wrong stage');
		assert.equal(tokenTotalSupply.toString(10), '0', 'Wrong token total supply');
		assert.equal(weiRaised.toString(10), '0', 'Wrong wei raised amount');
		assert.equal(rate.toString(10), RATE, 'Wrong rate');
	});

	it('Check an investment in presale fails', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();    

		let investorError = null;
		const investor = identity.next();

		try {
			await crowdsale.buyTokens(investor, { from: investor, value: toWei('1', 'ether') });
		} catch (error) {
			investorError = error;
		}

		assert.instanceOf(investorError, Error, 'Investor was able to buy tokens in presale');
	});

	it('Check investors whitelist and unwhitelist', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();

		await crowdsale.changeWhitelistParticipantsStatus(whitelisted, true, { from: addresses.owner, gas: 200000 });
		for (let investor of whitelisted) {
			const isWhitelisted = await crowdsale.isParticipantWhitelisted.call(investor);

			assert.equal(isWhitelisted, true, 'Unable to whitelist investor');
		}

		await crowdsale.changeWhitelistParticipantsStatus(whitelisted, false, { from: addresses.owner, gas: 200000 });
		for (let investor of whitelisted) {
			const isWhitelisted = await crowdsale.isParticipantWhitelisted.call(investor);

			assert.equal(isWhitelisted, false, 'Unable to unwhitelist investor');
		}
	});

	it('Check whitelist status change function gas limit', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();

		let overLimitError = null;

		try {
			await crowdsale.changeWhitelistParticipantsStatus(whitelisted, true, { from: addresses.owner, gas: 7000000 });
		} catch(e) {
			overLimitError = e;
		}

		await crowdsale.changeWhitelistParticipantsStatus(whitelisted, true, { from: addresses.owner, gas: 500000 });

		assert.instanceOf(overLimitError, Error, 'Could call whitelist status change function with gas amount over limit');
	});

	it('Check rate update', async function() {
		const snapshot = await evm.snapshot();

		const newRate = '940';
		const crowdsale = await VervVluxCrowdsale.deployed();
		let error = null;

		await crowdsale.updateRate(newRate, { from: addresses.owner });

		try {
			await crowdsale.updateRate('234', { from: addresses.wallet });
		} catch (e) { error = e }

		const rate = await crowdsale.rate.call();

		assert.equal(rate.toString(10), newRate, 'Unable to update rate');
		assert.instanceOf(error, Error, 'Anyone can update rate');

		await evm.revert(snapshot);
	});

	it('Check start time update', async function() {
		const snapshot = await evm.snapshot();

		const newStartTime = START_TIME + 1000;
		const pastStartTime = toTime('Thursday, March 1, 2018 0:00:00 AM GMT+00:00');
		const crowdsale = await VervVluxCrowdsale.deployed();
		let nonOwnerError = null;
		let equalEndTimeError = null;
		let pastStartTimeError = null;

		await crowdsale.updateStartTime(newStartTime, { from: addresses.owner });

		try {
			await crowdsale.updateStartTime(newStartTime, { from: addresses.wallet });
		} catch (e) { nonOwnerError = e }

		try {
			await crowdsale.updateStartTime(pastStartTime, { from: addresses.wallet });
		} catch (e) { pastStartTimeError = e }

		try {
			await crowdsale.updateStartTime(END_TIME, { from: addresses.owner });
		} catch (e) { equalEndTimeError = e }

		const startTime = await crowdsale.startTime.call();

		assert.equal(startTime.toString(10), newStartTime, 'Unable to update start time');
		assert.instanceOf(nonOwnerError, Error, 'Anyone can start time');
		assert.instanceOf(pastStartTimeError, Error, 'Start time can be set to date in the past');
		assert.instanceOf(equalEndTimeError, Error, 'Start time can exceed end time');

		await evm.revert(snapshot);
	});

	it('Check end time update', async function() {
		const snapshot = await evm.snapshot();

		const newEndTime = END_TIME + 1000;
		const crowdsale = await VervVluxCrowdsale.deployed();
		let nonOwnerError = null;
		let equalStartTimeError = null;
		let overLimitTimeError = null;

		await crowdsale.updateEndTime(newEndTime, { from: addresses.owner });

		try {
			await crowdsale.updateEndTime(newEndTime, { from: addresses.wallet });
		} catch (e) { nonOwnerError = e }

		try {
			await crowdsale.updateEndTime(START_TIME, { from: addresses.owner });
		} catch (e) { equalStartTimeError = e }

		try {
			await crowdsale.updateEndTime(MAX_END_TIME + 1000, { from: addresses.owner });
		} catch (e) { overLimitTimeError = e }

		const endTime = await crowdsale.endTime.call();

		assert.equal(endTime.toString(10), newEndTime, 'Unable to update end time');
		assert.instanceOf(nonOwnerError, Error, 'Anyone can end time');
		assert.instanceOf(equalStartTimeError, Error, 'End time can be below start time');
		assert.instanceOf(overLimitTimeError, Error, 'End time can be set to later than hard limit');

		await evm.revert(snapshot);
	});

	it('Check presale investment and wei raised', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();
		const tokenAddress = await crowdsale.token.call();
		const token = await VervVluxToken.at(tokenAddress);

		let errorContributionRate = null;
		let errorRewards = null;
		let errorContributions = null;
		const investor = identity.next();
		const investment = toWei(10, 'ether');
		const saft = { ether: toWei(6.25, 'ether'), tokens: toWei(50000, 'ether'), vesting: VestingDuration.Mo9 };

		await crowdsale.distributePreBuyersLkdRewards(
			investor,
			saft.tokens,
			saft.vesting,
			{ from: addresses.owner }
		);

		try {
			await crowdsale.distributePreBuyersLkdRewards(
				investor,
				saft.tokens,
				saft.vesting,
				{ from: addresses.wallet }
			);
		} catch (e) { errorRewards = e }

		const vestingAddress = await crowdsale.vestingContract.call(investor);
		const vesting = await TokenVesting.at(vestingAddress);
		const balance = await token.balanceOf.call(vestingAddress);
		const userBalance = await token.balanceOf.call(investor);
		const cliff = await vesting.cliff.call();
		const start = await vesting.start.call();
		const duration = await vesting.duration.call();
		const revocable = await vesting.revocable.call();

		testVesting.contract = vesting;
		testVesting.tokens = toBigNumber(saft.tokens);
		testVesting.investor = investor;

		let nonOwnerWeiIncrease = null;
		let nonOwnerWeiDecrease = null;

		try {
			await crowdsale.increasePresaleWeiRaised(saft.ether, {from: investor})
		} catch (e) {
			nonOwnerWeiIncrease = e;
		}

		await crowdsale.increasePresaleWeiRaised(saft.ether, {from: addresses.owner})

		const amountAfterIncrease = await crowdsale.presaleWeiRaised.call();

		try {
			await crowdsale.decreasePresaleWeiRaised(saft.ether, {from: investor})
		} catch (e) {
			nonOwnerWeiDecrease = e;
		}

		await crowdsale.decreasePresaleWeiRaised(saft.ether, {from: addresses.owner})

		const amountAfterDecrease = await crowdsale.presaleWeiRaised.call();

		// allow an error marge of 30 seconds
		assert.equal(cliff.sub(start).toString(10), '0', 'Wrong vesting cliff');
		assert.equal(start.toString(10), END_TIME + SEC_3MO, 'Wrong vesting start time');
		assert.equal(revocable, false, 'Tokens vesting is revocable');
		assert.equal(duration.toString(10), SEC_3MO * 3, 'Wrong vesting duration');
		assert.equal(balance.toString(10), toBigNumber(saft.tokens).toString(10), 'Wrong amount of tokens transfered');
		assert.equal(userBalance.toString(10), '0', 'Tokens are transfered to investor directly');
		assert.instanceOf(errorRewards, Error, 'Anyone is able to disburse presale investment (reward)');

		assert.equal(amountAfterIncrease, saft.ether, "Did not update presale wei raised correctly");
		assert.instanceOf(nonOwnerWeiIncrease, Error, "Anyone can update presale wei raised");
		assert.equal(amountAfterDecrease, 0, "Did not update presale wei raised correctly");
		assert.instanceOf(nonOwnerWeiDecrease, Error, "Anyone can update presale wei raised");
	});

	it('Check crowdsale start state', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();
		await evm.timeTravelTo(START_TIME + 10);

		await crowdsale.pause({from: addresses.owner});

		await crowdsale.decreaseCap(toWei( parseInt(cfg.cap) - 1, 'ether'), { from: addresses.owner });

		await crowdsale.unpause({from: addresses.owner});

		await crowdsale.increaseCap(toWei( parseInt(cfg.cap) + 2, 'ether'), { from: addresses.owner });

		const stage = await crowdsale.stage.call();
		
		assert.equal(stage.toString(10), Stages.Sale, 'Wrong stage');
	});

	it('Check cap update', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();

		const currentCap = await crowdsale.cap.call();
		const newCapIncrease = currentCap.add(toWei(1, 'ether'));
		const newCapDecrease = currentCap.sub(toWei(1, 'ether'));

		let updateWhenPausedError = null;
		let nonOwnerIncreaseError = null;
		let nonOwnerDecreaseError = null;
		let couldIncreaseCapThroughDecreaseError = null;
		let couldDecreaseCapThroughIncreaseError = null;

		try {
			await crowdsale.increaseCap(newCapIncrease, { from: addresses.wallet });
		} catch (e) { nonOwnerIncreaseError = e }

		try {
			await crowdsale.increaseCap(newCapDecrease, { from: addresses.owner });
		} catch (e) { couldDecreaseCapThroughIncreaseError = e }

		await crowdsale.increaseCap(newCapIncrease, { from: addresses.owner });
		const capAfterIncrease = await crowdsale.cap.call();

		await crowdsale.pause({from: addresses.owner});

		await crowdsale.decreaseCap(newCapDecrease, { from: addresses.owner });
		const capAfterDecrease = await crowdsale.cap.call();

		try {
			await crowdsale.decreaseCap(newCapIncrease, { from: addresses.wallet });
		} catch (e) { couldIncreaseCapThroughDecreaseError = e }

		try {
			await crowdsale.decreaseCap(newCapDecrease, { from: addresses.wallet });
		} catch (e) { nonOwnerDecreaseError = e }

		try {
			await crowdsale.decreaseCap(newCapDecrease, { from: addresses.wallet });
		} catch (e) { updateWhenPausedError = e }
		await crowdsale.unpause({from: addresses.owner});

		assert.equal(capAfterIncrease.toString(10), newCapIncrease.toString(10), 'Unable to increase cap');
		assert.equal(capAfterDecrease.toString(10), newCapDecrease.toString(10), 'Unable to decrease cap');
		assert.instanceOf(updateWhenPausedError, Error, 'Cap can be decreased while contract not paused');
		assert.instanceOf(nonOwnerIncreaseError, Error, 'Anyone can increase cap');
		assert.instanceOf(nonOwnerDecreaseError, Error, 'Anyone can decrease cap');
		assert.instanceOf(couldIncreaseCapThroughDecreaseError, Error, 'Cap can be increased through decrease function');
		assert.instanceOf(couldDecreaseCapThroughIncreaseError, Error, 'Cap can be decreased through increase function');
	});

	it('Check investment (incl. bonuses)', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();
		const tokenAddress = await crowdsale.token.call();
		const token = await VervVluxToken.at(tokenAddress);

		const day1Investment = toBigNumber(toWei(5, 'ether'));
		const day1TotalInvestment = toBigNumber(toWei(10, 'ether'));
		const investment = toBigNumber(toWei(13, 'ether'));

		const investor1 = whitelisted.shift(); // whitelisted for day 1, limited to 10 ETH
		const investor2 = whitelisted.shift(); // whitelisted for day 2
		const investor3 = whitelisted.shift(); // whitelisted for day 3
		const investor4 = identity.next(); // not whitelisted

		let day1ExceedOnetimeInvestmentError = null;
		let day1ExceedTotalInvestmentError = null;
		let day1NonWhitelistedError = null;
		let day2NonWhitelistedError = null;
		let day3NonWhitelistedError = null;

		await crowdsale.buyTokens(investor1, { from: investor1, value: day1Investment });

		try {
			await crowdsale.buyTokens(investor1, { from: investor1, value: investment });
		} catch (e) { day1ExceedOnetimeInvestmentError = e }

		await crowdsale.buyTokens(investor1, { from: investor1, value: day1Investment });
		try {
			await crowdsale.buyTokens(investor1, { from: investor1, value: day1Investment });
		} catch (e) { day1ExceedTotalInvestmentError = e }

		try {
			await crowdsale.buyTokens(investor4, { from: investor4, value: day1Investment });
		} catch (e) { day1NonWhitelistedError = e }

		// travel to day 2
		await evm.timeTravelTo(START_TIME + (60 * 60 * 24) + 10);

		await crowdsale.buyTokens(investor2, { from: investor2, value: investment });

		try {
			await crowdsale.buyTokens(investor4, { from: investor4, value: investment });
		} catch (e) { day2NonWhitelistedError = e }

		// travel to day 3
		await evm.timeTravelTo(START_TIME + (60 * 60 * 24) + (60 * 60 * 24) + 10);

		await web3.eth.sendTransaction({ from: investor3, to: crowdsale.address, value: investment, gas: 400000 });
		
		try {
			await crowdsale.buyTokens(investor4, { from: investor4, value: investment });
		} catch (e) { day3NonWhitelistedError = e }

		const investor1Balance = await token.balanceOf.call(investor1);
		const investor2Balance = await token.balanceOf.call(investor2);
		const investor3Balance = await token.balanceOf.call(investor3);
		const investor4Balance = await token.balanceOf.call(investor4);

		assert.equal(investor1Balance.toString(10), day1TotalInvestment.mul(DAY1_RATE).toString(10), 'Wrong amount of tokens transfered in day 1');
		assert.equal(investor2Balance.toString(10), investment.mul(DAY2_RATE).toString(10), 'Wrong amount of tokens transfered in day 2');
		assert.equal(investor3Balance.toString(10), investment.mul(RATE).toString(10), 'Wrong amount of tokens transfered in day 3');
		assert.instanceOf(day1ExceedOnetimeInvestmentError, Error, 'Investor is able to send more than 10 ETH in day 1');
		assert.instanceOf(day1ExceedTotalInvestmentError, Error, 'Investor is able to send more than 10 ETH in day 1 summarily');
		assert.instanceOf(day1NonWhitelistedError, Error, 'Non whitelisted participant can invest in day 1');
		assert.instanceOf(day2NonWhitelistedError, Error, 'Non whitelisted participant can invest in day 2');
		assert.instanceOf(day3NonWhitelistedError, Error, 'Non whitelisted participant can invest in day 3');
	});

	it('Check investment while paused', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();

		const investment = toWei(3, 'ether');
		const investor = identity.next();
		let pauseError = null;
		let investmentError = null;

		try {
			await crowdsale.pause({ from: addresses.wallet });
		} catch (e) { pauseError = e }

		await crowdsale.pause({ from: addresses.owner });

		const paused = await crowdsale.paused.call();

		try {
			await crowdsale.buyTokens(investor, { from: investor, value: investment });
		} catch (e) { investmentError = e }

		await crowdsale.unpause({ from: addresses.owner });

		const pausedAfter = await crowdsale.paused.call();

		assert.equal(paused, true, 'Can not put sale on pause');
		assert.equal(pausedAfter, false, 'Can not resume sale after putting it on pause');
		assert.instanceOf(pauseError, Error, 'Anyone can put sale on pause');
		assert.instanceOf(investmentError, Error, 'Participant can invest while sale paused');
	});

	it('Check transfer pause management', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();
		const newPauseManager = identity.next();

		let transferError = null;
		let transferFromOldManagerError = null;

		try {
			await crowdsale.transferPauseManagement(newPauseManager, {from: newPauseManager});
		} catch(e) {
			transferError = e;
		}

		await crowdsale.transferPauseManagement(newPauseManager, {from: addresses.owner});

		await crowdsale.pause({from: newPauseManager});
		let isPaused = await crowdsale.paused.call();
		assert.equal(isPaused, true, 'New pause manager could not pause contract')
		
		await crowdsale.unpause({from: newPauseManager});
		isPaused = await crowdsale.paused.call();
		assert.equal(isPaused, false, 'New pause manager could not pause contract')

		const pauseManager = await crowdsale.pauseManager.call();

		assert.equal(pauseManager, newPauseManager, 'Pause manager did not set correctly.');
		assert.instanceOf(transferError, Error, 'Anyone can transfer pause management role');
	})

	it('Check finalization by cap', async function() {
		const snapshot = await evm.snapshot();

		const crowdsale = await VervVluxCrowdsale.deployed();
		const tokenAddress = await crowdsale.token.call();
		const token = await VervVluxToken.at(tokenAddress);

		const investor = whitelisted.shift();
		const cap = await crowdsale.cap.call();
		const weiRaisedBefore = await crowdsale.weiRaised.call();
		const investment = cap.sub(weiRaisedBefore);
		
		await crowdsale.buyTokens(investor, { from: investor, value: investment });

		const stage = await crowdsale.stage.call();
		const weiRaised = await crowdsale.weiRaised.call();
		const walletBalance = await web3.eth.getBalance(addresses.wallet);
		const investorBalance = await token.balanceOf.call(investor);

		assert.equal(weiRaised.toString(10), cap.toString(10), 'Wrong amount of wei reised');
		assert.equal(weiRaised.toString(10), investment.add(weiRaisedBefore).toString(10), 'Wrong amount of ether invested');
		assert.isAtLeast(parseInt(fromWei(walletBalance).toString(10)), parseInt(fromWei(weiRaised).toString(10)), 'Wrong balance on wallet');
		assert.equal(investorBalance.toString(10), investment.mul(RATE).toString(10), 'Wrong amount of tokens was transfered to investor');
		assert.equal(stage.toString(10), Stages.SaleOver, 'Unable to finalize sale by cap');

		await evm.revert(snapshot);
	});
	
	it('Check finalization by time (incl. dictribution)', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();
		const tokenAddress = await crowdsale.token.call();
		const token = await VervVluxToken.at(tokenAddress);

		let secondFinalizeError = null;
		let investmentError = null;

		await evm.timeTravelTo(END_TIME + 10);

		const totalTokensBefore = await token.totalSupply.call();

		crowdsale.finalize({ from: addresses.wallet });

		try {
			await crowdsale.finalize({ from: addresses.owner });
		} catch (e) { secondFinalizeError = e }

		try {
			await crowdsale.buyTokens(addresses.owner, { from: addresses.owner, value: toWei(1, 'ether') });
		} catch (e) { investmentError = e }

		const stage = await crowdsale.stage.call();
		const isFinalized = await crowdsale.isFinalized.call();
		const totalTokens = await token.totalSupply.call();
		const mintingFinished = await token.mintingFinished.call();
		const companyBalance = await token.balanceOf.call(addresses.companyWallet);

		assert.isAbove(parseInt(totalTokens.toString(10)), parseInt(totalTokensBefore.toString(10)), 'Wrong amount of tokens distributed');
		assert.approximately(parseFloat(fromWei(companyBalance).toString(10)), parseFloat(fromWei(totalTokens.div(100).mul(COMPANY_DIST)).toString(10)), MAX_DIST_ERROR_MARGE, 'Wrong amount of tokens distributed to company wallet');
		assert.instanceOf(secondFinalizeError, Error, 'Sale can be finalized several times');
		assert.instanceOf(investmentError, Error, 'Participant can invest after sale end');
		assert.equal(stage.toString(10), Stages.SaleOver, 'Unable to finalize sale by time');
		assert.equal(isFinalized, true, 'Finalization state not logged');
		assert.equal(mintingFinished, true, 'Tokens can be created after sale end');
	});

	it('Check presale SAFT vesting', async function() {
		const crowdsale = await VervVluxCrowdsale.deployed();
		const tokenAddress = await crowdsale.token.call();
		const token = await VervVluxToken.at(tokenAddress);

		const start = await testVesting.contract.start.call();
		const duration = await testVesting.contract.duration.call();
		const balanceBefore = await token.balanceOf.call(testVesting.investor);
		const end = start.add(duration);
		const mid = start.add(duration.div(2));

		await evm.timeTravelTo(parseInt(start.toString(10)));

		const startAmount = await testVesting.contract.releasableAmount.call(token.address);

		await evm.timeTravelTo(parseInt(mid.toString(10)));

		const midAmount = await testVesting.contract.releasableAmount.call(token.address);

		await evm.timeTravelTo(parseInt(end.toString(10)));

		const endAmount = await testVesting.contract.releasableAmount.call(token.address);

		await testVesting.contract.release(token.address, { from: testVesting.investor });

		const afterAmount = await testVesting.contract.releasableAmount.call(token.address);
		const balance = await token.balanceOf.call(testVesting.investor);
		const vestingBalance = await token.balanceOf.call(testVesting.contract.address);

		assert.approximately(parseFloat(fromWei(startAmount).toString(10)), 0, MAX_DIST_ERROR_MARGE, 'Wrong vesting start amount');
		assert.approximately(parseFloat(fromWei(midAmount).toString(10)), parseFloat(fromWei(testVesting.tokens.div(2)).toString(10)), MAX_DIST_ERROR_MARGE, 'Wrong vesting mid term amount');
		assert.approximately(parseFloat(fromWei(endAmount).toString(10)), parseFloat(fromWei(testVesting.tokens).toString(10)), MAX_DIST_ERROR_MARGE, 'Wrong vesting end amount');
		assert.equal(afterAmount.toString(10), '0', 'Tokens available after releasing vested amount');
		assert.equal(vestingBalance.toString(10), '0', 'Tokens available on vesting contract balance');
		assert.equal(balanceBefore.toString(10), '0', 'Tokens transfered to investor before vesting occurs');
		assert.equal(balance.toString(10), testVesting.tokens.toString(10), 'Wrong amount of tokens transfered to investor after vesting end');
	});
});
