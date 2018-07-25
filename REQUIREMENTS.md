## Requirements

Token requirements:

- [x] Standard: “ERC20”
- [x] Decimals: “18”
- [x] Name “Vlux by Verv”
- [x] Symbol “VLX”
- [x] Extends “MintableToken”
- [x] Extends “Ownable”
- [x] Initial supply is undefined

ITO requirements:

- [x] Extends “Ownable”
- [x] Extends “Pausable”
- [x] Start time is “Wednesday, July 4, 2018 4:00:00 PM GMT+00:00” editable before start
- [x] End time is “Saturday, July 7, 2018 4:00:00 PM GMT+00:00” editable before start
- [x] Rate is “2000 FLX/ETH” editable before start
- [x] Investments are transferred to a multisig “wallet”
- [x] Tokens retained by the “company” - 30% transferred after sale end
- [x] Ability to add addresses to whitelist available before start
- [x] Bonus day 1 - “5%”
- [x] Bonus day 2 - “2.5%”
- [x] Bonus day 3 - “0%”
- [x] Day 1 allows whitelisted addresses to contribute a maximal amount of “10 ETH”
- [x] Day 2 allows whitelisted addresses to contribute any amount
- [x] Day 3 allows anyone to contribute any amount
- [x] Presale investment using function distributePreBuyersLkdRewards(investor, tokens, vesting)” available before start
- [x] Presale investment using function disbursePreBuyersLkdContributions(investor, rate, vesting)” available before start (must be used real ether)
- [x] Maximal rate for presale investment (disbursePreBuyersLkdContributions) is 8000
- [x] Make possible updating ETH cap where `newCap > oldCap` (to match the cap target defined in white paper)
- [x] Finish minting after the ITO ends

Vesting requirements:

- [x] Lockup period is calculated from the sale end time
- [x] Non revocable (once created we can not revoke distributed tokens)
- [x] Available vesting duration periods - 3 months, 6 months, 12 months
- [x] Vesting occurs second-by-second (after 3 months lockup period)

> Requirements document can be found [here](https://docs.google.com/document/d/1vlb29sP17eWXRxJUBcBjonPCEwwmjEJO5mrtQ1uvc-4/edit)
