# BLAKE2B Gas Golfing Incentivizer

A POC for a smart contract that incentivizes EVM implementations of BLAKE2b per this [@zooko twitter thread](https://twitter.com/zooko/status/1053797772686778368). For reference, see [this EIP](https://github.com/ethereum/EIPs/issues/152). Submissions look like:

1. Call `commit` with the address of a smart contract implementing BLAKE2b in a function matching the signature below.
2. After >10 blocks have elapsed, call `testCommitment` with the same address. If that function call consumes less gas than the current record (set at 100k to start), and the output matches the output of the reference implementation, then the contract will pay out 1 ether + .0004 ether * gasSaved to the address.

[The reference BLAKE2b implementation](https://github.com/ConsenSys/Project-Alchemy).

Note: this hasn't been tested or deployed, and is still in a working state.

## Solidity interface
```solidity
interface BLAKE2bCaller {
    function blake2b(bytes input, bytes key, uint64 outlen) external pure returns (uint64[8]);
}

interface Incentivizer {
    function commit(address _address) external;
    function testCommitment(address _address) external;

    function contractBalance() external view returns (uint balanceInWei);
    function () external payable;

    event ContractFunded(uint amountInWei, uint newBalanceInWei);
    event CommitmentMade(address winner, uint testBlock);
    event NewRecord(address winner, uint oldGasRecord, uint newGasRecord);
}
```
