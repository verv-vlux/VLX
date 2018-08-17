pragma solidity 0.4.19;

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

// File: contracts/VervVluxToken.sol

contract VervVluxToken is MintableToken, BurnableToken { // token is burnable in compliance with the whitepaper
    string public name = "Vlux by Verv";
    string public symbol = "VLUX";
    uint8 public decimals = 18;
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

}

// File: zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/TokenVesting.sol

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

// File: contracts/VervVluxCrowdsale.sol

contract VervVluxCrowdsale is CappedCrowdsale, Ownable, Pausable {
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
    // _cap = to be defined in compliance with the whitepaper
    function VervVluxCrowdsale(
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

    // Update sale cap to keep it in compliance with the whitepaper
    function increaseCap(uint256 newCap)
        public
        onlyOwner
        transitionGuard
        beforeStage(Stages.SaleOver)
    {
        require(newCap > weiRaised);
        require(newCap > cap);

        uint256 oldCap = cap;
        cap = newCap;

        CapUpdated(oldCap, cap);
    }

    function decreaseCap(uint256 newCap)
        public
        onlyOwner
        whenPaused
        transitionGuard
        beforeStage(Stages.SaleOver)
    {
        require(newCap > weiRaised);
        require(newCap < cap);

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
        return new VervVluxToken();
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

// File: contracts/Migrations.sol

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function Migrations() public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}
