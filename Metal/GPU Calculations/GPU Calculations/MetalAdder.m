//
//  MetalAdder.m
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/11.
//

#import "MetalAdder.h"


// The number of floats in each array, and the size of the arrays in bytes.
const unsigned int arrayLength = 1 << 24;
const unsigned int bufferSize = arrayLength * sizeof(float);

@implementation MetalAdder
{
    
    id<MTLComputePipelineState> _mAddFunctionPSO;
    id <MTLCommandQueue> _mCommandQueue;
    
    id<MTLBuffer> _mBufferA;
    id<MTLBuffer> _mBufferB;
    id<MTLBuffer> _mBufferResult;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init])
    {
        self.device = device;
        id <MTLLibrary> defaultLibrary = [device newDefaultLibrary];
        if (defaultLibrary == nil)
        {
            NSLog(@"Failed to find the default library.");
            return nil;
        }
        id<MTLFunction> addFunction = [defaultLibrary newFunctionWithName:@"add_arrays"];
        if (addFunction == nil)
        {
            NSLog(@"Failed to find the adder function.");
            return nil;
        }
        // 准备 Pipeline
        NSError *error;
        _mAddFunctionPSO = [device newComputePipelineStateWithFunction:addFunction error:&error];
        _mCommandQueue = [self.device newCommandQueue];

    }
    return self;
}


- (void)prepareData
{
    _mBufferA = [self.device newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    _mBufferB = [self.device newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    _mBufferResult = [self.device newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
    
    [self generateRandomFloatData:_mBufferA];
    [self generateRandomFloatData:_mBufferB];
}

- (void)sendComputeCommand
{
    // 1. 创建命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    id<MTLComputeCommandEncoder> computerEncoder = [commandBuffer computeCommandEncoder];
    
    // 设置 compute
    [self encodeAddCommand:computerEncoder];

    [computerEncoder endEncoding];
    
    [commandBuffer commit];
    
    [commandBuffer waitUntilCompleted];
    
    [self verifyResults];
}

- (void)encodeAddCommand:(id<MTLComputeCommandEncoder>)computeEncoder {
    
    // 设置状态
    [computeEncoder setComputePipelineState:_mAddFunctionPSO];
    // 丢数据
    [computeEncoder setBuffer:_mBufferA offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBufferB offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBufferResult offset:0 atIndex:2];
    
    // 需要构建几个线程
    MTLSize gridSize = MTLSizeMake(arrayLength, 1, 1);
    
    // 计算线程组size
    NSUInteger threadGroupSize = _mAddFunctionPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > arrayLength)
    {
        threadGroupSize = arrayLength;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];
}


- (void)generateRandomFloatData: (id<MTLBuffer>) buffer
{
    float* dataPtr = buffer.contents;
    for (unsigned long index = 0; index < arrayLength; index++)
    {
        dataPtr[index] = (float)rand()/(float)(RAND_MAX);
    }
}

- (void) verifyResults
{
    float* a = _mBufferA.contents;
    float* b = _mBufferB.contents;
    float* result = _mBufferResult.contents;

    for (unsigned long index = 0; index < arrayLength; index++)
    {
        if (result[index] != (a[index] + b[index]))
        {
            printf("Compute ERROR: index=%lu result=%g vs %g=a+b\n",
                   index, result[index], a[index] + b[index]);
            assert(result[index] == (a[index] + b[index]));
        }
    }
    printf("Compute results as expected\n");
}


@end
