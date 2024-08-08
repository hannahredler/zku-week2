//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Groth16Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root
    constructor() {
        
        for (uint i=0; i< 8; i++) {
            hashes.push(0);
        }

        uint currPointer = 0;
        uint currArraySize = 8;

        while (currArraySize > 1) {
            for (uint i = 0; i < currArraySize/2; i++) {
                hashes.push(PoseidonT3.poseidon([hashes[currPointer], hashes[currPointer+1]]));
                currPointer++;
            }
            currArraySize = currArraySize/2;
        }

        root = hashes[hashes.length - 1];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        if (index == 4) revert("Tree full!");
        hashes[index] = hashedLeaf;
        
        uint currArraySize = 8;
        uint currArrayStartPointer = 0;
        uint currIndex = index;

        while (currArraySize > 1) {
            uint toAdd = (currIndex-currArrayStartPointer)/2 ; // this is how far from the start of the new array I need to go
            uint newCurrIndex = currArrayStartPointer + currArraySize + toAdd;
            if (index % 2 == 0) {
                // left leaf
                hashes[newCurrIndex] = PoseidonT3.poseidon([hashes[currIndex], hashes[currIndex+1]]);
            } else {
                // right leaf
                hashes[newCurrIndex] = PoseidonT3.poseidon([hashes[currIndex-1], hashes[currIndex]]);
            }

            currIndex = newCurrIndex;
            currArrayStartPointer = currArrayStartPointer + currArraySize;
            currArraySize = currArraySize/2;
        } 

        index++;

        return hashes[hashes.length-1];
    }

    function verify(
            uint[2] calldata  a,
            uint[2][2] calldata b,
            uint[2] calldata c,
            uint[1] calldata input
        ) public view returns (bool) {

        
        return verifyProof(a, b, c, input);
    }
}
