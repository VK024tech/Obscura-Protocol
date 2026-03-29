pragma circom 2.1.6;

include "poseidon.circom";
include "@zk-kit/binary-merkle-root.circom/src/binary-merkle-root.circom";



template Withdraw(MAX_DEPTH){
    // Public inputs
    signal input root;
    signal input nullifierHash;
    signal input signalHash;
   

    // Private inputs
    signal input secret;
    signal input nullifier;

    signal input recipient;
    
    signal input relayer;
    
    signal input relayerFee;
   

    signal input chainId;
    signal input contractAddress;
    
    
    signal input siblings[MAX_DEPTH];
    signal input index;

    // Internal signals
    signal calculatedNullifierHash;

    // Compute the commitment
    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== nullifier;
   

    // verify the merkle proof
    component tree = BinaryMerkleRoot(MAX_DEPTH);
    tree.leaf <== commitmentHasher.out;
    tree.index <== index;
    tree.depth <== MAX_DEPTH;
  

    for (var i = 0; i < MAX_DEPTH; i++){
        tree.siblings[i] <== siblings[i];
    }

    tree.out === root;

    // compute the nullifier hash
    component nullifierHasher = Poseidon(1);
    nullifierHasher.inputs[0] <== nullifier;
   
    calculatedNullifierHash <== nullifierHasher.out;


    // enforce equality 
    calculatedNullifierHash === nullifierHash;

    component signalHasher = Poseidon(5);
    signalHasher.inputs[0] <== recipient;
    signalHasher.inputs[1] <== relayer;
    signalHasher.inputs[2] <== relayerFee;
    signalHasher.inputs[3] <== chainId;
    signalHasher.inputs[4] <== contractAddress;

    signalHasher.out === signalHash;
}

component main { public [root, nullifierHash, signalHash] } = Withdraw(20);