pragma circom 2.1.9;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 

    var nLeaves = 2**n; // 4
    signal input leaves[nLeaves];
    signal output root;

    component poseidons[2**n - 1];

    var nHashes = nLeaves/2;

    assert(root == 1);
    for (var i = 0; i < nHashes; i++) {
        poseidons[i] = Poseidon(2);
        poseidons[i].inputs[0] <== leaves[i*2]; 
        poseidons[i].inputs[1] <== leaves[i*2 + 1];
    }

    var pointerStart = 0;
    nHashes = nHashes/2;

    for (var i = 0; i < n - 1; i++) {
        
        for (var j = 0; j < nHashes; j++) {
            var hashPosition = pointerStart + nHashes + j;
            poseidons[hashPosition] = Poseidon(2);
            poseidons[hashPosition].inputs[0] <== poseidons[pointerStart + j*2].out;
            poseidons[hashPosition].inputs[1] <== poseidons[pointerStart + j*2 + 1].out;
        }

        pointerStart += nHashes;
        nHashes = nHashes/2;
    }

    root <== poseidons[2**n -2].out;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal
    
    component poseidons[n];
    component selectors[n];

    poseidons[0] = Poseidon(2);
    selectors[0] = MultiMux1(2);

    selectors[0].c[0][0] <== leaf;
    selectors[0].c[0][1] <== path_elements[0];
    selectors[0].c[1][0] <== path_elements[0];
    selectors[0].c[1][1] <== leaf;

    selectors[0].s <== path_index[0];

    poseidons[0].inputs[0] <== selectors[0].out[0];
    poseidons[0].inputs[1] <== selectors[0].out[1];

    for (var i = 1 ; i < n; i++) {

        poseidons[i] = Poseidon(2);
        selectors[i] = MultiMux1(2);

        selectors[i].c[0][0] <== poseidons[i-1].out;
        selectors[i].c[0][1] <== path_elements[0];
        selectors[i].c[1][0] <== path_elements[0];
        selectors[i].c[1][1] <== poseidons[i-1].out;

        selectors[i].s <== path_index[0];

        poseidons[i].inputs[0] <== selectors[i].out[0];
        poseidons[i].inputs[1] <== selectors[i].out[1];
    }

    root <== poseidons[n-1].out;
}