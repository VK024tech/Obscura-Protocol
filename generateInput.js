const circomlib = require("circomlibjs");
const crypto = require("crypto");
const fs = require("fs");

function rbigint() {
  return BigInt("0x" + crypto.randomBytes(31).toString("hex"));
}

async function main() {
  const poseidon = await circomlib.buildPoseidon();
  const F = poseidon.F;

  const MAX_DEPTH = 1; // must match Withdraw(1)

  // Generate random private inputs
  const secret = rbigint();
  const nullifier = rbigint();
  const recipient = rbigint();

  // Compute commitment = Poseidon(secret, nullifier)
  const commitment = poseidon([secret, nullifier]);

  // Compute nullifierHash = Poseidon(nullifier, recipient)
  const nullifierHash = poseidon([nullifier, recipient]);

  // Build 1-level Merkle tree
  const sibling = rbigint();
  const index = 0; // leaf on left side

  // Compute root depending on index
  let root;
  if (index === 0) {
    root = poseidon([commitment, sibling]);
  } else {
    root = poseidon([sibling, commitment]);
  }

  const input = {
    root: F.toString(root),
    nullifierHash: F.toString(nullifierHash),
    recipient: recipient.toString(),

    secret: secret.toString(),
    nullifier: nullifier.toString(),

    depth: "1",
    index: index.toString(),
    siblings: [sibling.toString()]
  };

  fs.writeFileSync("input.json", JSON.stringify(input, null, 2));
  console.log("✅ input.json generated successfully");
}

main();