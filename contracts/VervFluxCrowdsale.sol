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
    uint256 constant public MAX_PRESALE_RATE = 8000;

    // Predefined value mappings
    mapping (uint => uint256) public vestingDurations;
    mapping (address => uint256) public finalizationRetainStrategy;
    mapping (uint => uint256) public bonuses;

    // Whitelisted participants
    mapping (address => bool) public whitelist;

    // Tokens vesting
    mapping (address => TokenVesting) public vestingContracts;

    // Sale status
    Stages public stage = Stages.PreSale;
    address public companyWallet;
    bool public isFinalized = false;
    
    event Finalized();
    event WhitelistParticipant(address indexed investor);
    event CapUpdated(uint256 cap, uint256 newCap);
    event StageUpdated(uint stage, uint newStage);

    // Check the stage to be the specified one
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    // Check the stage to be before specified one
    modifier beforeStage(Stages _stage) {
        require(uint(stage) < uint(_stage));
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

    // Constructor
    // _owner = (TBD)
    // _companyWallet = (TBD)
    // _wallet = (TBD)
    // _cap = £20M * ETH/£ rate
    function VervFluxCrowdsale(
        address _owner,
        address _companyWallet,
        address _wallet, 
        uint256 _cap
    )
        public
        Crowdsale(
            1522454400, // startTime (Saturday, March 31, 2018 12:00:00 AM)
            1522800000, // endTime (Wednesday, April 4, 2018 12:00:00 AM)
            2000, // rate
            _wallet // wallet
        )
        CappedCrowdsale(_cap)
    {
        require(_owner != 0x0);
        require(_companyWallet != 0x0);

        owner = _owner;
        companyWallet = _companyWallet;

        // Define tokens percentage retained by company
        finalizationRetainStrategy[companyWallet] = 34;

        // Define vesting periods
        vestingDurations[uint(VestingDuration.Mo3)] = 1 years / 4;
        vestingDurations[uint(VestingDuration.Mo6)] = 1 years / 2;
        vestingDurations[uint(VestingDuration.Mo9)] = 1 years / 4 * 3;
        vestingDurations[uint(VestingDuration.Mo12)] = 1 years;
    }

    /************ Public functionality ************/

    // Check if participant was whitelisted
    function isParticipantWhitelisted(address investor) public view returns (bool) {
        return whitelist[investor];
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return stage == Stages.SaleOver;
    }

    // Invest function
    function buyTokens(address beneficiary)
        public
        payable
        whenNotPaused
        transitionGuard
        atStage(Stages.Sale)
    {
        require(validInvestment(beneficiary));

        super.buyTokens(beneficiary);
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

        uint256 campanyRetainPerc = finalizationRetainStrategy[companyWallet];
        uint256 tokensDistributed = token.totalSupply();
        uint256 investorsMarge = 100 - campanyRetainPerc;

        require(tokensDistributed > 0);

        uint256 totalTokens = tokensDistributed / investorsMarge * 100;
        uint256 companyDist = totalTokens * campanyRetainPerc / 100;

        token.mint(companyWallet, companyDist);

        token.finishMinting();
        Finalized();
    }

    // Retrieve vesting contracts
    function vestingContract(address beneficiary) public view returns (TokenVesting) {
        return vestingContracts[beneficiary];
    }

    /************ Owner functionality ************/

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
        require(newStartTime > 0);
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
        require(newEndTime > 0);
        require(newEndTime > startTime);

        endTime = newEndTime;
    }

    // Update sale cap to keep it £20M
    function updateCap(uint256 newCap)
        public
        onlyOwner
        transitionGuard
        beforeStage(Stages.SaleOver)
    {
        require(newCap > cap);

        uint256 oldCap = cap;
        cap = newCap;

        CapUpdated(oldCap, cap);
    }

    // Whitelist participant
    function whitelistParticipant(address investor)
        public
        whenNotPaused
        onlyOwner
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(investor != 0x0);

        whitelist[investor] = true;

        WhitelistParticipant(investor);
    }

    // Disburse presale investment with real funds sent
    function disbursePreBuyersLkdContributions(
        address beneficiary,
        uint256 rate,
        VestingDuration vestingDuration
    )
        public
        payable
        onlyOwner
        transitionGuard
        atStage(Stages.PreSale)
    {
        require(msg.value > 0);
        require(rate > 0);
        require(rate <= MAX_PRESALE_RATE);

        uint256 tokensAmount = msg.value * rate;

        distributePreBuyersLkdRewards(
            beneficiary,
            tokensAmount,
            vestingDuration
        );

        forwardFunds();
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
        
        uint256 duration = vestingDurations[uint(vestingDuration)];

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

    /************ Internal functionality ************/

    // Make the stage transition if the case
    function transition() internal {
        // If it's time to start the sale
        if (stage == Stages.PreSale && now > startTime) {
            nextStage();
        }

        // If sale running and wither cap or endTime is reached
        if (stage == Stages.Sale && super.hasEnded()) {
            nextStage();
        }
    }

    // Creates the token to be sold.
    function createTokenContract() internal returns (MintableToken) {
        return new VervFluxToken();
    }

    // Validate investment
    function validInvestment(address beneficiary) internal view returns (bool) {
        bool allowedToInvest = false;
        bool validAmount = false;

        if (now < (startTime + 2 days)) { // Allow only whitelisted addresses to invest first 2 days
            allowedToInvest = isParticipantWhitelisted(beneficiary);

            if (now < (startTime + 1 days)) { // Allow max. investment of 10 ETH on first day
                validAmount = msg.value <= MAX_ALLOWED_FIRST_DAY_INVESTMENT;
            } else {
                validAmount = true;
            }
        } else {
            allowedToInvest = true;
            validAmount = true;
        }

        return allowedToInvest && validAmount;
    }

    // Get token amount to transfer
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 finalRate = rate;

        if (now < (startTime + 1 days)) {
            finalRate = rate + (rate * 150 / 1000); // 15% bonus
        } else if (now < (startTime + 2 days)) {
            finalRate = rate + (rate * 125 / 1000); // 12.5% bonus
        } else if (now < (startTime + 3 days)) {
            finalRate = rate + (rate * 100 / 1000); // 10% bonus
        }

        return weiAmount * finalRate;
    }

    // Transit to the next stage
    function nextStage() internal {
        uint oldStage = uint(stage);
        uint newStage = oldStage + 1;

        stage = Stages(newStage);

        StageUpdated(oldStage, newStage);
    }
}
