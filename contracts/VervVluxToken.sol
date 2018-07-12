pragma solidity 0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

contract VervVluxToken is MintableToken, BurnableToken { // token is burnable in compliance with the whitepaper
    string public name = "Vlux by Verv";
    string public symbol = "VLUX";
    uint8 public decimals = 18;
}
