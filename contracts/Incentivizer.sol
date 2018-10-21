pragma solidity ^0.4.24;

import "./blake2b/BLAKE2b.sol";

interface BLAKE2bCaller {
    function blake2b(bytes input, bytes key, uint64 outlen) external pure returns (uint64[8]);
}

contract Incentivizer is BLAKE2b {
    uint commitmentBlocks;
    uint currentGasRecord;
    uint payoutPerWinner;
    uint payoutPerGas;

    mapping (address => uint) commitments;

    constructor() public {
        commitmentBlocks = 10;
        currentGasRecord = 100000;
        payoutPerWinner = 1 ether;
        payoutPerGas = 400000000000000;
    }

    function commit(address _address) public {
        require(commitments[_address] == 0, "Addresses can only commit once.");
        commitments[_address] = block.number + commitmentBlocks;
        emit CommitmentMade(_address, commitments[_address]);
    }

    function testCommitment(address _address) public {
        require(commitments[_address] >= block.number - 256, "Commitments can only be tested within 256 blocks.");
        require(block.number > commitments[_address], "Commitments can only be tested after the required interval.");

        // convert blockhash to bytes input
        bytes32 commitmentBlockhash = blockhash(commitments[_address]);
        bytes memory input = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            input[i] = commitmentBlockhash[i];
        }

        // get the reference hash
        uint64[8] memory referenceHash = blake2b(input, "", 64);

        // get the commitment hash
        uint gasBefore = gasleft();
        uint64[8] memory computedHash = BLAKE2bCaller(_address).blake2b(input, "", 64);
        uint gasConsumed = gasBefore - gasleft();

        // ensure the two are equal
        for (uint j = 0; j < 32; j++) {
            require(referenceHash[j] == computedHash[j], "Hashes were not equal.");
        }

        // pay out if required
        payout(_address, gasConsumed);
    }

    function payout(address winningAddress, uint gasConsumed) private {
        if (gasConsumed < currentGasRecord) {
            // TODO implement log-based payouts
            uint amount = payoutPerWinner + (currentGasRecord - gasConsumed) * payoutPerGas;
            winningAddress.transfer(amount);
            emit NewRecord(winningAddress, amount, currentGasRecord, gasConsumed);
            currentGasRecord = gasConsumed;
        }
    }

    function contractBalance() public view returns (uint balanceInWei) {
        return address(this).balance;
    }

    function () public payable {
        if (msg.value > 0) {
            emit ContractFunded(msg.value, contractBalance());
        }
    }

    event ContractFunded(uint amountInWei, uint newBalanceInWei);
    event CommitmentMade(address _address, uint testBlock);
    event NewRecord(address winner, uint rewardInWei, uint oldGasRecord, uint newGasRecord);
}
