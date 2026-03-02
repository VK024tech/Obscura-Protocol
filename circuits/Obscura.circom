pragma circom 2.1.6;

include "circomlib/circuits/poseidon.circom";
include "@zk-kit/binary-merkle-root.circom/src/binary-merkle-root.circom";


template Withdraw(MAX_DEPTH){
    // Public inputs
     signal input root;
    signal input nullifierHash;
    signal input recipient;

    // Private inputs
    signal input secret;
    signal input nullifier;
    
    signal input siblings[MAX_DEPTH];
    signal input index;
    signal input depth;

    // Internal signals
    signal commitment;
    signal calculatedNullifierHash;

    // Compute the commitment
    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== nullifier;
    commitment <== commitmentHasher.out;

    // verify the merkle proof
    component tree = BinaryMerkleRoot(MAX_DEPTH);
    tree.leaf <== commitment;
    tree.depth <== depth;
    tree.index <== index;
  

    for (var i = 0; i < MAX_DEPTH; i++){
        tree.siblings[i] <== siblings[i];
    }

    // tree.out === root;

    // compute the nullifier hash
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== nullifier;
    nullifierHasher.inputs[1] <== recipient;
    calculatedNullifierHash <== nullifierHasher.out;


    // enforce equality 
    // calculatedNullifierHash === nullifierHash;

}

component main { public [root, nullifierHash, recipient] } = Withdraw(1);