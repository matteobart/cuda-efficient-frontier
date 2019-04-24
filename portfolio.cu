#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <curand.h>
#include <curand_kernel.h>
//to get data yahoo finance
//time period: Apr 01 2016 -> Apr 01 2019
//freq: Weekly
#define NUM_ELEMENTS 100 //why when I change this everything breaks
#define NUM_PORTFOLIOS atoi(argv[argc])
#define MAX_NUM_OF_STOCKS 158


float* readFile(char* filename){
    float* ret = (float*) malloc(NUM_ELEMENTS*sizeof(float));
    FILE* ptr = fopen(filename,"r");
    if (ptr==NULL) 
    { 
        printf("Error reading file"); 
        return 0; 
    } 
    char line[255];
    char* token;
    int lineCount = 0; 
    fgets(line, 255, ptr); //grab the first line and do nothing
    while (fgets(line, 255, ptr) != 0 && lineCount < NUM_ELEMENTS){ //for each line
        int dataCount = 0;
        token = strtok(line, ",");
        while (token != 0) { //for each word in line
            if (dataCount == 5) {
                ret[lineCount] = atof(token);
            }
            token = strtok(0, ",");
            dataCount++;
        }
        lineCount++;
    }
    fclose(ptr);
    return ret;
}

void writeFile(char* filename, float* returns, float* risk, int len){
    FILE* ptr = fopen(filename, "w");
    for (int a = 0; a < len; a++){
        fprintf(ptr, "%f %f\n", risk[a], returns[a]);
    }
    fclose(ptr);

}

float getAverage(float* nums, int len){
    float sum = 0;
    for (int a = 0; a < len; a++){
        sum += nums[a];
    }
    return sum/len;
}

float* getPercentReturns(float* nums, int len){
    float* ret = (float*) malloc(sizeof(float)*(len-1));
    for (int a = 0; a < len-1; a++){
        ret[a] = (nums[a+1]-nums[a])/nums[a]; 
    }
    return ret; 
}

//a few possible errors in here
//still need to plot
//why am I mallocing
void gold(int argc, char* argv[]){
    argc--;
    if (argc < 3) {
        printf("%s\n", "Expected more arguments");
        exit(0);
    } 

    float** closingPrices = (float**) malloc(sizeof(float*)*(argc-1));
    float** returns = (float**) malloc(sizeof(float*)*(argc-1));
    float* averages = (float*) malloc(sizeof(float)*(argc-1));

    for (int a = 1; a < argc; a++){
        closingPrices[a-1] = readFile(argv[a]);
        returns[a-1] = getPercentReturns(closingPrices[a-1], NUM_ELEMENTS);
        averages[a-1] = getAverage(returns[a-1], NUM_ELEMENTS-1);
    }

    for (int a = 0; a < (argc-1); a++){
        for (int b = 0; b < (NUM_ELEMENTS-1); b++){
            printf("Returns %d %d: %f \n", a, b, returns[a][b]);
        }
    }

    for (int a = 0; a < argc-1; a++){
        printf("avg %d: %f\n", a, averages[a]);
    }

    //calculate the standard deviation
    float* std = (float*) malloc(sizeof(float)*(argc-1));
    for (int a = 0; a < argc-1; a++){
        for (int b = 0; b < NUM_ELEMENTS-1; b++){
            std[a] += pow(returns[a][b]-averages[a], 2);   
        }
        std[a] /= NUM_ELEMENTS-2;
        std[a] = sqrt(std[a]);
    }

    for (int a = 0; a < argc-1; a++){
        printf("Std %d: %f \n", a, std[a]);
    }

    //calculate the covariances for each of the stocks 
    //doing extra things [0][4] will be the same as [4][0]
    float** covariance = (float**) malloc(sizeof(float*)*(argc-1));
    for (int a = 0; a < argc-1; a++){
        covariance[a] = (float*) malloc(sizeof(float)*(argc-1));
        for (int b = 0; b < argc-1; b++){
            float sum = 0;
            for (int c = 0; c < NUM_ELEMENTS-1; c++){
                sum += (returns[a][c] - averages[a]) * (returns[b][c] - averages[b]);
            }
            sum /= NUM_ELEMENTS-2;
            covariance[a][b] = sum;
            printf("%f\n", sum);
        }
    }

    //time to choose the weights for the given portfolios
    //PSUDEO:
        //for doing random weights
        //if x stocks 
        //then choose x numbers
        //then find the sum of the randoms
        //then divide each random number by sum
    clock_t start = clock(), diff;
   
    srand(time(NULL));   // Initialization, should only be called once.
    float* risk = (float*) malloc(sizeof(float)* NUM_PORTFOLIOS);
    float* reward =(float*) malloc(sizeof(float)* NUM_PORTFOLIOS);
    for (int a = 0; a < NUM_PORTFOLIOS; a++){//find the risk & reward for each portfolio
        float randomWeights[argc-1]; //may actually want to save this for later
        int totalWeight = 0;
        for (int b = 0; b < argc-1; b++){//choose random weights
            int r = rand() % 100;  //RAND MIGHT BE DOING THE SAME VAL EVERYTIME
            totalWeight += r;  
            randomWeights[b] = (float) r;
        }
        for (int b = 0; b < argc-1; b++){//now random weight has the correct weights
            randomWeights[b] /= totalWeight;
        }

        //first find the reward
        float totalReward = 0;
        for (int b = 0; b < argc-1; b++){
            totalReward += averages[b]*randomWeights[b];

        }
        reward[a] = totalReward;

        //find the risk of the portfolio
        float totalRisk = 0;
        float work[argc-1];
        for (int b = 0; b < argc-1; b++){
            work[b] = 0;
            for (int c = 0; c < argc-1; c++){
                work[b] += randomWeights[c]*covariance[c][b];
            }
        }
        for (int b = 0; b < argc-1; b++){
            totalRisk += work[b] * randomWeights[b];
        }

        risk[a] = sqrt(totalRisk);
        if (a==0){
            for (int r = 0; r < argc-1;r++) printf("randomWeights: %f\n", randomWeights[r]);
            printf("Risk: %f\n", risk[a]);
            for (int r = 0; r < argc-1; r++){
                for (int rr = 0; rr < argc-1; rr++){
                    printf("Cov of %d %d : %f\n", r, rr, covariance[r][rr]);
                }
            }
        } 
    }

    diff = clock() - start;
    int msec = diff * 1000 / CLOCKS_PER_SEC;
    printf("Time taken for just portfolios %d seconds %d milliseconds\n", msec/1000, msec%1000);
    

    //plot the data
    writeFile("riskreturngold.txt", reward, risk, NUM_PORTFOLIOS);

}

__constant__ float c_returns[MAX_NUM_OF_STOCKS * 99];
__constant__ float c_averages[MAX_NUM_OF_STOCKS];
__constant__ float c_std[MAX_NUM_OF_STOCKS];

__global__ void GPercentReturns(float* closingPrices, float* returns, int numOfStocks)
{
    __shared__ float closing[NUM_ELEMENTS];
    int stockId = blockIdx.x;
    int returnId = threadIdx.x; 

    int grab = returnId + (stockId * NUM_ELEMENTS); //also write 2

    //everyone load into shared
    closing[returnId] = closingPrices[grab];
    __syncthreads();

    if (returnId != NUM_ELEMENTS-1){//last thread should do this
        int to = returnId + (stockId*(NUM_ELEMENTS-1));
        returns[to] = (closing[returnId+1]-closing[returnId])/closing[returnId];

    }
    //int grab2 = returnId+1 + (stockId * NUM_ELEMENTS); 

    //returns[to] = (closingPrices[grab2]-closingPrices[grab1])/closingPrices[grab1];
}

//where mid is greater power of 2 less than or equal to number of elements
__global__ void GReduceAverage(float* average, int numOfStocks, int mid){
    int returnId = threadIdx.x;
    //int stockId = blockIdx.x;
    //int dim = blockDim.x;

    float tot = 0; 
    for(int a = 0; a < NUM_ELEMENTS-1; a++){
        tot += c_returns[a+(returnId*(NUM_ELEMENTS-1))];
    }
    average[returnId] = tot / (float) (NUM_ELEMENTS-1);
    /*
    if (returnId<mid && returnId+mid<dim){
        returns[(stockId*dim)+returnId]+=returns[(stockId*dim)+returnId+mid];
    }
    for (int s = mid/2; s > 0; s/=2){
        if (returnId < s) {
            returns[(stockId*dim)+returnId] += returns[(stockId*dim)+returnId+s];
        }
    }
    if(returnId == 0){
        average[stockId] = returns[stockId*dim]/dim;
    }*/
    
}


__global__ void GStd(float* std, int numOfStocks, int mid){
    extern __shared__ float s_std[];
    int returnId = threadIdx.x;
    int stockId = blockIdx.x;
    int dim = blockDim.x;
    float add = powf(c_returns[stockId*(NUM_ELEMENTS-1)+returnId]-c_averages[stockId], 2);
    s_std[returnId] = add;
    __syncthreads();

    //if (returnId<mid && returnId+mid<dim){
    //    s_std[returnId]+=s_std[returnId+mid];
    //}

    if (returnId>=mid){
        s_std[returnId-mid]+=s_std[returnId];
    }
    __syncthreads();
    for (int s = mid/2; s > 0; s/=2){
        if (returnId < s) {
            s_std[returnId]+=s_std[returnId+s];
        }
        __syncthreads();
    }


    //atomicAdd(&std[stockId], powf(returns[stockId*(NUM_ELEMENTS-1)+returnId]-averages[stockId], 2));
    __syncthreads();
    if (returnId == 0) {
        std[stockId]= sqrt(s_std[0]/(NUM_ELEMENTS-2));
    }
}   

__global__ void GCovariance(float* covariance, int numberOfStocks){
   // __shared__ float s_returns[]

    int b = threadIdx.x;
    int a = threadIdx.y;

    float sum = 0;
    for (int c = 0; c < NUM_ELEMENTS-1; c++)
        sum += (c_returns[a*(NUM_ELEMENTS-1)+c] - c_averages[a]) * (c_returns[b*(NUM_ELEMENTS-1)+c] - c_averages[b]);
    
    sum /= NUM_ELEMENTS-2;
    covariance[a*numberOfStocks+b] = sum;
}


__global__ void GPortfolio(curandState*state, float* covariance, float* risk, float* reward, int numberOfStocks, int mid){
    //obscene amount of global calls here
    //only one call to risk[] and reward[] at the end
    //also there might be a GPU version of sqrt()
    extern __shared__ float sharedMemory[];
    float* randomWeights = (float*) &sharedMemory[0];
    float* scratch = (float*) &sharedMemory[numberOfStocks];
    
    //__shared__ float randomWeights[16];
    //__shared__ float scratch[16];


    int tid = threadIdx.x;
    int bid = blockIdx.x;

    float r = curand_uniform(&state[tid+bid*blockDim.x]);
    
    //RAN WEIGHT
    //FAST- WORKS
    randomWeights[tid] = r;
    __syncthreads();
    //quick reduce
    if (tid >= mid){
    //if (tid<mid && tid+mid<numberOfStocks){
        //randomWeights[tid] += randomWeights[tid+mid];

        randomWeights[tid-mid] += randomWeights[tid];
    }
    __syncthreads();

    for (int s = mid/2; s > 0; s /= 2){
        if (tid < s) 
            randomWeights[tid] += randomWeights[tid+s];
        __syncthreads();
    }
    float totalWeight = randomWeights[0];
    __syncthreads();
    randomWeights[tid] = (float) r/ totalWeight;

    //SLOW-IGNORE
    // randomWeights[tid] = r;
    // __syncthreads();
    // atomicAdd(&randomWeights[0], r);
    // __syncthreads();
    // float totalWeight = randomWeights[0];
    // __syncthreads();
    // randomWeights[tid] = r/totalWeight;

    //RETURN
    //FAST


    scratch[tid] = c_averages[tid]*randomWeights[tid];
    __syncthreads();
    if (tid >= mid){
        scratch[tid-mid] += scratch[tid];
        if (tid >= numberOfStocks) printf("%d\n", tid);
        if (tid-mid < 0) printf("%d", tid-mid);
    }
    __syncthreads();
    for (int s = mid/2; s > 0; s /= 2){
        if (tid < s) {
            scratch[tid] += scratch[tid+s];
            //printf("i %d %d\n",tid ,tid+s);

        }
        __syncthreads();
    }
    reward[bid] = scratch[0];
    __syncthreads();

    //SLOW
    // reward[bid] = 0;
    // atomicAdd(&reward[bid], averages[tid]*randomWeights[tid]);
    // __syncthreads();
    //if (tid == 0) printf("%d: %f %f\n", bid, reward[bid], deleteMe);

    //RISK
    //FAST
    float work = 0;
    for (int c = 0; c < numberOfStocks; c++){
         work += randomWeights[c]*covariance[c*numberOfStocks+tid];
    }
    scratch[tid] = work*randomWeights[tid];

    __syncthreads();
    if (tid >= mid){
        scratch[tid-mid] += scratch[tid];
    }
    __syncthreads();

    for (int s = mid/2; s > 0; s /= 2){
        if (tid < s) 
            scratch[tid] += scratch[tid+s];
        __syncthreads();
    }
    risk[bid] = sqrt(scratch[0]);

    //SLOW
    // float work = 0;
    // for (int c = 0; c < numberOfStocks; c++){
    //      work += randomWeights[c]*covariance[c*numberOfStocks+tid];
    // }

    // atomicAdd(&risk[bid], work * randomWeights[tid]);
    // __syncthreads();
    // if (tid == 0)
    //     risk[bid] = sqrt(risk[bid]);
}

__global__ void init_stuff(curandState*state){int idx=blockIdx.x*blockDim.x+threadIdx.x;curand_init(1337,idx,0,&state[idx]);}


void gpu (int argc, char* argv[]) {
    argc--;
    float* closingPrices = (float*) malloc(sizeof(float)*(argc-1)*NUM_ELEMENTS);
    float* returns = (float*) malloc(sizeof(float)*(argc-1)*(NUM_ELEMENTS-1));
    float* averages = (float*) malloc(sizeof(float)*(argc-1));

    for (int a = 1; a < argc; a++){
        float* add = readFile(argv[a]);
        for (int b = 0; b < NUM_ELEMENTS; b++){
            closingPrices[(a-1)*NUM_ELEMENTS+b] = add[b];
        }
    }
    float* d_closingPrices;
    cudaMalloc(&d_closingPrices, sizeof(float) * (argc-1)*NUM_ELEMENTS);

    float* d_returns;
    cudaMalloc(&d_returns, sizeof(float) * (argc-1)*(NUM_ELEMENTS-1));


    float* d_averages;
    cudaMalloc(&d_averages, sizeof(float) * (argc-1));

    cudaMemcpy(d_closingPrices, closingPrices, sizeof(float)*(argc-1)*NUM_ELEMENTS, cudaMemcpyHostToDevice);


    dim3 blockSize (NUM_ELEMENTS-1, argc-1);
    GPercentReturns<<<argc-1,NUM_ELEMENTS>>>(d_closingPrices, d_returns, argc-1);
    cudaMemcpy(returns, d_returns, sizeof(float)*(argc-1)*(NUM_ELEMENTS-1), cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize(); //is this needed here
    cudaMemcpyToSymbol(c_returns, returns, sizeof(float) * (argc-1)*(NUM_ELEMENTS-1));

    for (int a = 0; a < (argc-1); a++){
        for (int b = 0; b < (NUM_ELEMENTS-1); b++){
            printf("Returns %d %d: %f \n", a, b, returns[a*(NUM_ELEMENTS-1)+b]);
        }
    }

    float* d_work; //should be init with returns
    cudaMalloc(&d_work, sizeof(float)*(argc-1)*(NUM_ELEMENTS-1));
    cudaMemcpy(d_work, d_returns, sizeof(float)*(argc-1)*(NUM_ELEMENTS-1),cudaMemcpyDeviceToDevice);
    //NUM_ELEMENTS/2 because its reduce... may change
    int mid = 1;
    while (mid * 2 <= NUM_ELEMENTS-1) {
        mid *= 2;
    }
    //smater
    //GReduceAverage<<<argc-1, NUM_ELEMENTS/2>>>(d_work, d_averages, argc-1, mid);
    //dumber
    GReduceAverage<<<1, argc-1>>>(d_averages, argc-1, mid);
    cudaMemcpy(averages, d_averages, sizeof(float)*(argc-1), cudaMemcpyDeviceToHost);
    cudaMemcpyToSymbol(c_averages, averages, sizeof(float) * (argc-1));

    for (int a = 0; a < argc-1; a++){
        printf("avg %d: %f\n", a, averages[a]);
    }

    float* std = (float*) malloc(sizeof(float)*(argc-1));

    float* d_std;
    cudaMalloc(&d_std, sizeof(float)*(argc-1)); 

    GStd<<<argc-1, NUM_ELEMENTS-1, sizeof(float)*(NUM_ELEMENTS-1)>>>(d_std, argc-1, mid);

    cudaMemcpy(std, d_std, sizeof(float)*(argc-1), cudaMemcpyDeviceToHost);
    cudaMemcpyToSymbol(c_std, std, sizeof(float) * (argc-1));

    for (int a = 0; a < argc-1; a++){
        printf("Std %d: %f \n", a, std[a]);
    }

    float* covariance = (float*) malloc(sizeof(float)*(argc-1)*(argc-1));//2D like array
    float* d_covariance;
    cudaMalloc(&d_covariance, sizeof(float)*(argc-1)*(argc-1));
    
    blockSize.x = argc-1;
    blockSize.y = argc-1;
    GCovariance<<<1,blockSize>>>(d_covariance, argc-1);
    cudaMemcpy(covariance, d_covariance, sizeof(float)*(argc-1)*(argc-1), cudaMemcpyDeviceToHost);

    for (int a = 0; a < argc-1; a++){
        for (int b = 0; b <argc-1; b++){
            printf("Cov %d %d: %f\n", a, b, covariance[a*(argc-1)+b]);
        }
    }

    //timing just for portfolio
    float time;
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);
    //END

    float* risk = (float*) malloc(sizeof(float)*NUM_PORTFOLIOS);
    float* reward = (float*) malloc(sizeof(float)*NUM_PORTFOLIOS);
    float* d_risk;
    float* d_reward;
    cudaMalloc(&d_risk, sizeof(float)*NUM_PORTFOLIOS);
    cudaMalloc(&d_reward, sizeof(float)*NUM_PORTFOLIOS);

    curandState*d_state;
    cudaMalloc(&d_state,(argc-1)*NUM_PORTFOLIOS);
    init_stuff<<<NUM_PORTFOLIOS,argc-1>>>(d_state);

    mid = 1;
    while (mid * 2 <= argc-1){
        mid *= 2;
    }
    GPortfolio<<<NUM_PORTFOLIOS, argc-1, (sizeof(float)*(argc-1))*2>>>(d_state, d_covariance, d_risk, d_reward, argc-1, mid);
    printf("Middy %d\n",mid);
    cudaMemcpy(risk, d_risk, sizeof(float)*NUM_PORTFOLIOS, cudaMemcpyDeviceToHost);
    cudaMemcpy(reward, d_reward, sizeof(float)*NUM_PORTFOLIOS, cudaMemcpyDeviceToHost);

    cudaDeviceSynchronize();

    //START
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaError_t code = cudaEventElapsedTime(&time, start, stop);
    if (code != cudaSuccess) {
      fprintf(stderr,"GPUassert: %s\n", cudaGetErrorName(code));
      
    }
    //END
    printf("Time for portfolio: %f s\n", time/1000);

    writeFile("riskreturn.txt", reward, risk, NUM_PORTFOLIOS);

}
//to plot
//in terminal do 
//gnuplot
//plot 'riskreturn.txt' with points pt 3



int main( int argc, char* argv[])
{

    clock_t start = clock(), diff;
    gold(argc, argv);
    diff = clock() - start;
    int msec = diff * 1000 / CLOCKS_PER_SEC;
    printf("Time taken %d seconds %d milliseconds\n", msec/1000, msec%1000);
    

    clock_t start2 = clock(), diff2;
    gpu(argc, argv);
    diff2 = clock() - start2;
    int msec2 = diff2 * 1000 / CLOCKS_PER_SEC;
    printf("Time taken %d seconds %d milliseconds\n", msec2/1000, msec2%1000);


    return 0;
}