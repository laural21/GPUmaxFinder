/*
 * To compile: nvcc maxgpu.cu
 */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda.h>
#include <math.h>

unsigned int getmax(unsigned int *, unsigned int);
__global__ void getmaxcu(unsigned int num[], unsigned int size);

int main(int argc, char *argv[])
{
    unsigned int size = 0;  // The size of the array
    unsigned int i;  // loop index
    unsigned int * numbers; //pointer to the array
    unsigned int * numbers_d; //pointer to the numbers array on the device

    if(argc !=2)
    {
        printf("usage: maxseq num\n");
        printf("num = size of the array\n");
        exit(1);
    }

    size = atol(argv[1]);
    //int numBlocks = ceil(size/1024);

    numbers = (unsigned int *)malloc(size * sizeof(unsigned int));
    numbers_d = (unsigned int *)malloc(size * sizeof(unsigned int));

    if( !numbers )
    {
        printf("Unable to allocate mem for an array of size %u\n", size);
        exit(1);
    }

    srand(time(NULL)); // setting a seed for the random number generator
    // Fill-up the array with random numbers from 0 to size-1
    for( i = 0; i < size; i++)
        numbers[i] = rand() % size;

    //printf(" The maximum number in the array is: %u\n",
    //       getmax(numbers, size));

    /*
     * 1. allocate device memory
     * 2. copy numbers array to device
     * 3. each SM finds local max
     * 4. write back to host
     */
    cudaMalloc((void**)&numbers_d, size* sizeof(unsigned int));
    cudaMemcpy(numbers_d, numbers, size* sizeof(unsigned int), cudaMemcpyHostToDevice);

    getmaxcu<<<1, 1024>>>(numbers_d, size);

    cudaMemcpy(&numbers[0], &numbers_d[0], sizeof(unsigned int), cudaMemcpyDeviceToHost);
    cudaFree(numbers_d);

    printf("The maximum number in the array is %u\n", numbers[0]);
    free(numbers);
    exit(0);
}


/*
   input: pointer to an array of long int
          number of elements in the array
   output: the maximum number of the array
*/
unsigned int getmax(unsigned int num[], unsigned int size)
{
    unsigned int i;
    unsigned int max = num[0];

    for(i = 1; i < size; i++)
        if(num[i] > max)
            max = num[i];

    return( max );
}
/*
 * Find max in own section of the array, keep updating max.
 */
__global__ void getmaxcu(unsigned int num[], unsigned int size){
    int i = blockIdx.x *blockDim.x + threadIdx.x;
    int stop = i + size/1024;

    for(i; i < stop; i++){
        if(num[i] > num[0])
            num[0] = num[i];
    }
}
