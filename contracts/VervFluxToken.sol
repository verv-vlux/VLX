pragma solidity 0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";

contract VervFluxToken is MintableToken, BurnableToken {
    string public name = "Verv Flux";
    string public symbol = "VLUX";
    uint8 public decimals = 18;
}
