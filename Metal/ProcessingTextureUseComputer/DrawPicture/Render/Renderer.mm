//
//  Renderer.m
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#import "Renderer.h"
#import "DefineTypes.h"
#include "stb_image.h"
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>

@implementation Renderer
{
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLRenderPipelineState> _pipelineState;
    id<MTLComputePipelineState> _computePipelineState;

    id <MTLBuffer> _vertexBuffer; // 纹理数据
    
    // 输入的纹理
    id<MTLTexture> _inputTexture;
    // 输出的纹理
    id<MTLTexture> _outputTexture;
    
    // Compute kernel dispatch parameters
    MTLSize _threadgroupSize;
    MTLSize _threadgroupCount;
}

- (instancetype)initWithMTKView:(MTKView *)view
{
    if (self = [super init])
    {
        _device = view.device;
        _commandQueue = [_device newCommandQueue];
        [self setupBuffers];
        [self setPipleLine:view];
        [self setComputerPipleline];
        [self setupTexture];
        [self setThreadGroup];
    }
    return self;
}

- (void)setComputerPipleline
{
    id<MTLLibrary> library = [_device newDefaultLibrary];
    id<MTLFunction> gray_fun = [library newFunctionWithName:@"grayscaleKernel"];
    NSError *error;
    _computePipelineState = [_device newComputePipelineStateWithFunction:gray_fun error:&error];
    NSAssert(_computePipelineState, @"Failed to create compute pipeline state: %@", error);
}

- (void)setThreadGroup
{
    _threadgroupSize = MTLSizeMake(16, 16, 1);

    // 线程组的行+ 列
    _threadgroupCount.width  = (_inputTexture.width  + _threadgroupSize.width -  1) / _threadgroupSize.width;
    _threadgroupCount.height = (_inputTexture.height + _threadgroupSize.height - 1) / _threadgroupSize.height;
    // The image data is 2D, so set depth to 1.
    _threadgroupCount.depth = 1;
}

- (void)setPipleLine:(MTKView * _Nonnull)view
{
    id<MTLLibrary> library = [_device newDefaultLibrary];
    id<MTLFunction> vertext_fun = [library newFunctionWithName:@"vertextShader"];
    id<MTLFunction> fragment_fun = [library newFunctionWithName:@"fragmentShader"];
    
    // 构建描述符
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.label = @"渲染到屏幕";
    pipelineDescriptor.vertexFunction = vertext_fun;
    pipelineDescriptor.fragmentFunction = fragment_fun;
    pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineDescriptor.sampleCount = 1;
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
}

- (void)setupBuffers
{
    static const VertextObject quadVertices[] =
    {
        // Positions     , Texture coordinates
        // 左下
        { {  -1.0, -1.0 },  { 0.0, 1.0 } },
        // 左上
        { { -1.0,  1.0 },  { 0.0, 0.0 } },
        // 右下
        { { 1.0, -1.0 },  { 1.0, 1.0 } },
        // 右上
        { { 1.0,  1.0},  { 1.0, 0.0 } },
    };
    
    // 创建一个buffer 防止每次都拷贝数据
    _vertexBuffer = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:(MTLResourceCPUCacheModeDefaultCache)];
}
- (void)setupTexture
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"wallhaven-3kvqm9.jpeg" ofType:nil];
    if (!path)
    {
        NSLog(@"路径为空");
        return;
    }
    NSImage *image = [NSImage imageNamed:@"wallhaven-3kvqm9"];
    NSRect rect = NSMakeRect(0, 0, image.size.width, image.size.height);
    CGImageRef imageRef = [image CGImageForProposedRect:&rect context:nil hints:nil];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef bitmapContext = CGBitmapContextCreate(rawData, width, height,
                                                       bitsPerComponent, bytesPerRow, colorSpace,
                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(bitmapContext);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    _inputTexture = [_device newTextureWithDescriptor:textureDescriptor];
    
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
    _outputTexture = [_device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [_inputTexture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    free(rawData);
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    // 处理计算纹理
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:_computePipelineState];

    [computeEncoder setTexture:_inputTexture atIndex:0];
    [computeEncoder setTexture:_outputTexture  atIndex:1];
    
    [computeEncoder dispatchThreadgroups:_threadgroupCount
                   threadsPerThreadgroup:_threadgroupSize];
    [computeEncoder endEncoding];

    
    // step2: 展示纹理
    MTLRenderPassDescriptor *descriptor = view.currentRenderPassDescriptor;
    descriptor.colorAttachments[0].texture = drawable.texture;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    [encoder setRenderPipelineState:_pipelineState];
    // 设置数据
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [encoder setFragmentTexture:_outputTexture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];

    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
