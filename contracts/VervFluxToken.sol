pragma solidity 0.4.19;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";


contract VervFluxToken is MintableToken {
    string public name = "Verv Flux";
    string public symbol = "FLX";
    uint8 public decimals = 18;
}
