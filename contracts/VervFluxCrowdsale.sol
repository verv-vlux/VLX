pragma solidity 0.4.19;

import "./VervFluxToken.sol";
import "zeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20/TokenVesting.sol";


contract VervFluxCrowdsale is CappedCrowdsale, Ownable, Pausable {
    using SafeMath for uint256;

    enum Stages {
        PreSale,
        Sale,
        SaleOver
    }

    enum VestingDuration {
        Mo3,
        Mo6,
        Mo9,
        Mo12
    }

    // Invariants
    uint256 constant public MAX_ALLOWED_FIRST_DAY_INVESTMENT = 10 ether; // 10 ETH allowed during 1'st day
    uint256 constant public PRESALE_LOCKUP_PERIOD = 1 years / 4; // 3 months lockup
    uint8 constant public COMPANY_RETAIN_PERCENT = 30;
    uint8 constant public INVESTOR_MARGIN = 70;
    uint256 constant public MAX_WHITELIST_TRANSACTION_GAS_AMOUNT = 4000000;
    uint256 constant public MAX_GAS_PRICE = 50000000000; // 50 gwei
    uint256 constant public END_TIME_LIMIT = 1546344000; //hard upper limit for end time - 1 Jan 2019

    // Predefined value mappings
    mapping (uint8 => uint256) public vestingDurations;

    // Whitelisted participants
    mapping (address => bool) public whitelist;

    // Tokens vesting
    mapping (address => TokenVesting) public vestingContracts;

    // Sale status
    Stages public stage = Stages.PreSale;
    address public companyWallet;
    bool public isFinalized = false;
    mapping (address => uint256) public firstDaySaleRecords;
    uint256 public presaleWeiRaised = 0;
    
    event Finalized();
    event WhitelistParticipant(address indexed investor);
    event CapUpdated(uint256 cap, uint256 newCap);
    event StageUpdated(uint8 stage, uint8 newStage);
    event PauseManagementTransferred(address indexed previousManager, address indexed newManager);

    address public pauseManager;

    // Check the stage to be the specified one
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    // Check the stage to be before specified one
    modifier beforeStage(Stages _stage) {
        require(uint8(stage) < uint8(_stage));
        _;
    }

    // Performs stage transition
    // this modifier first, otherwise the guards
    // will not take the new stage into account.
    modifier transitionGuard() {
        transition();
        _;
        transition();
    }

    modifier runsForThreeDays(uint256 _startTime, uint256 _endTime) {
        require(_endTime == _startTime + 3 days);
        _;
    }

    modifier underGasLimit() {
        require(msg.gas <= MAX_WHITELIST_TRANSACTION_GAS_AMOUNT);
        _;
    }

    modifier underGasPrice() {
        require(tx.gasprice <= MAX_GAS_PRICE);
        _;
    }

    modifier onlyPauseManager() {
        require(msg.sender == pauseManager);
        _;
    }

    // Constructor
    // _owner = (TBD)
    // _companyWallet = (TBD)
    // _wallet = (TBD)
    // _cap = amount of wei equivalent to £20M
    function VervFluxCrowdsale(
        address _owner,
        address _companyWallet,
        address _wallet, 
        uint256 _cap,
        uint256 _startTime
    )
        public
        Crowdsale(
            _startTime, // startTime (Wednesday, July 4, 2018 4:00:00 PM UTC)
            _startTime + (24 hours * 3), // endTime (Saturday, July 7, 2018 4:00:00 PM UTC)
            2000, // rate
            _wallet // wallet
        )
        CappedCrowdsale(_cap)
    {
        require(_owner != 0x0);
        require(_companyWallet != 0x0);

        owner = _owner;
        companyWallet = _companyWallet;
        pauseManager = _owner;

        // Define vesting periods
        vestingDurations[uint8(VestingDuration.Mo3)] = 1 years / 4;
        vestingDurations[uint8(VestingDuration.Mo6)] = 1 years / 2;
        vestingDurations[uint8(VestingDuration.Mo9)] = 1 years / 4 * 3;
        vestingDurations[uint8(VestingDuration.Mo12)] = 1 years;
    }

    /************ Public functionality ************/
    // Check if participant was whitelisted
    function isParticipantWhitelisted(address investor) public view returns (bool) {
        return whitelist[investor];
    }

    // Invest function
    function buyTokens(address beneficiary)
        public
        payable
        whenNotPaused
        underGasPrice
        transitionGuard
        atStage(Stages.Sale)
    {
        require(validInvestment(beneficiary));

        super.buyTokens(beneficiary);

        if (now < (startTime + 1 days)) {
            firstDaySaleRecords[beneficiary] = firstDaySaleRecords[beneficiary].add(msg.value);
        }
    }

    // Properly finalize crowdsale
    function finalize()
        public
        whenNotPaused
        transitionGuard
        atStage(Stages.SaleOver)
    {
        require(!isFinalized);

        isFinalized = true;

        uint256 tokensDistributed = token.totalSupply();

        require(tokensDistributed > 0);

        uint256 totalTokens = tokensDistributed.mul(100).div(INVESTOR_MARGIN);
        uint256 companyDist = totalTokens.mul(COMPANY_RETAIN_PERCENT).div(100);

        token.mint(companyWallet, companyDist);

        token.finishMinting();
        Finalized();
    }

    // Retrieve vesting contracts
    function vestingContract(address beneficiary) public view returns (TokenVesting) {
        return vestingContracts[beneficiary];
    }

    /************ Owner functionality ************/
    // Transfer pause management
    function transferPauseManagement(address newManager)
        public
        onlyPauseManager
    {
        require(newManager != 0x0);

        address previousManager = pauseManager;
        pauseManager = newManager;

        PauseManagementTransferred(previousManager, newManager);
    }

    // Update rate
    function updateRate(uint256 newRate)
        public
        onlyOwner
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(newRate > 0);

        rate = newRate;
    }

    // Update start time
    function updateStartTime(uint256 newStartTime)
        public
        onlyOwner
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(newStartTime > now);
        require(newStartTime < endTime);

        startTime = newStartTime;
    }

    // Update end time
    function updateEndTime(uint256 newEndTime)
        public
        onlyOwner
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(newEndTime > startTime);
        require(newEndTime < END_TIME_LIMIT);

        endTime = newEndTime;
    }

    // Update sale cap to keep it £20M
    function updateCap(uint256 newCap)
        public
        onlyOwner
        whenPaused
        transitionGuard
        beforeStage(Stages.SaleOver)
    {
        require(newCap > weiRaised);

        uint256 oldCap = cap;
        cap = newCap;

        CapUpdated(oldCap, cap);
    }

    // Whitelist participant
    function changeWhitelistParticipantsStatus(address[] investors, bool status)
        public
        whenNotPaused
        onlyOwner
        underGasLimit
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(investors.length > 0);

        for (uint256 i = 0; i < investors.length; i++) {
            require(investors[i] != 0x0);
            whitelist[investors[i]] = status;

            WhitelistParticipant(investors[i]);
        }
    }

    // Disburse presale investment
    function distributePreBuyersLkdRewards(
        address beneficiary,
        uint256 tokensAmount,
        VestingDuration vestingDuration
    )
        public
        whenNotPaused
        onlyOwner
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(beneficiary != 0x0);
        require(tokensAmount > 0);
        
        uint256 duration = vestingDurations[uint8(vestingDuration)];

        require(duration > 0);

        if (vestingContracts[beneficiary] == TokenVesting(0x0)) {
            vestingContracts[beneficiary] = new TokenVesting(
                beneficiary, // beneficiary
                endTime + PRESALE_LOCKUP_PERIOD, // start
                0, // cliff
                duration, // duration
                false // revocable
            );
        }

        token.mint(address(vestingContracts[beneficiary]), tokensAmount);
    }

    function increasePresaleWeiRaised(uint256 weiAmount) public onlyOwner {
        presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    }

    function decreasePresaleWeiRaised(uint256 weiAmount) public onlyOwner {
        presaleWeiRaised = presaleWeiRaised.sub(weiAmount);
    }

    /*** Pause manager functionality */
    function pause() public onlyPauseManager whenNotPaused {
        paused = true;
        Pause();
    }

    function unpause() public onlyPauseManager whenPaused {
        paused = false;
        Unpause();
    }

    /************ Internal functionality ************/
    // Make the stage transition if the case
    function transition() internal {
        // If it's time to start the sale
        if (stage == Stages.PreSale && now > startTime) {
            nextStage();
        }

        // If sale running and either cap or endTime is reached
        if (stage == Stages.Sale && super.hasEnded()) {
            nextStage();
        }
    }

    // Creates the token to be sold.
    function createTokenContract() internal returns (MintableToken) {
        return new VervFluxToken();
    }

    function validTotalFirstDayAmount(address beneficiary) internal view returns (bool) {
        return (firstDaySaleRecords[beneficiary] + msg.value) <= 10 ether;
    }

    // Validate investment
    function validInvestment(address beneficiary) internal view returns (bool) {
        bool allowedToInvest = isParticipantWhitelisted(beneficiary);
        bool validAmount = false;

        if (now < (startTime + 1 days)) { // Allow max. investment of 10 ETH on first day
            allowedToInvest = allowedToInvest && validTotalFirstDayAmount(beneficiary);
            validAmount = msg.value <= MAX_ALLOWED_FIRST_DAY_INVESTMENT;
        } else {
            validAmount = true;
        }

        return allowedToInvest && validAmount;
    }

    // Get token amount to transfer
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 finalRate = rate;

        if (now < (startTime + 1 days)) {
            finalRate = rate + (rate.mul(5).div(100)); // 5% bonus
        } else if (now < (startTime + 2 days)) {
            finalRate = rate + (rate.mul(25).div(1000)); // 2.5% bonus
        }

        return weiAmount * finalRate;
    }

    // Transit to the next stage
    function nextStage() internal {
        uint8 oldStage = uint8(stage);
        uint8 newStage = oldStage + 1;

        stage = Stages(newStage);

        StageUpdated(oldStage, newStage);
    }
}
