// alright, here's our C function to create our pseudo random input values
// to reiterate, we need a hash function that will:
// - be roughly evenly distributed in a range from 0 to max(int24)
// - accept inputs from the domain 0 to max(uint24)
//
// there's another issue later on, which is that we will need another hashing function 
// to produce the vector arrays we need.
// the problem is that these arrays need to have only unique values.
// so the hashing function we use to generate them need to be one-to-one across the 
// domain and range we're interested in, probably just 0 to max(int243)
//
// this is more difficult and i dont know if multiplicative hashing works that way
//
// note: easy copy and paste from the c to cuda file here, just have to modify a couple things 

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include <cuda.h>
#include <cuda_runtime.h>

#include "hvm.h"

#define BENDSIZEINT 8388608
#define BENDSIZEUINT 16777216

Port hashgrab(GNet* gnet, Port arg) {

    int amount = readback_bytes(gnet, arg);

    char* seeds = malloc(sizeof(char) * 3 * amount);
    FILE* seedfile = fopen("/dev/urandom", "r");
    fread(&seeds, sizeof(char) * 3 * amount, 1, seedfile);
    fclose(seedfile);
    
    char* int24array = malloc(sizeof(char) * 3 * amount);
    for (int i = 0; i < amount; i++) {
        int24array[i] = srand(seeds[i]);
    }

    free(seeds);
    return int24array;
}
