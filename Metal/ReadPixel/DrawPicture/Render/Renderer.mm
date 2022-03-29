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
    
    // 读取到的数据
    id<MTLBuffer> _readBuffer;
    
    // 输入的纹理
    id<MTLTexture> _texture;
    BOOL _drewSceneForReadThisFrame;

}

- (instancetype)initWithMTKView:(MTKView *)view
{
    if (self = [super init])
    {
        // 允许拷贝
        view.framebufferOnly = NO;
        ((CAMetalLayer*)view.layer).allowsNextDrawableTimeout = NO;
        view.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        
        _device = view.device;
        _commandQueue = [_device newCommandQueue];
        [self setupBuffers];
        [self setPipleLine:view];
        [self setComputerPipleline];
        [self setupTexture];
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
    _texture = [_device newTextureWithDescriptor:textureDescriptor];

    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [_texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
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
    commandBuffer.label = @"Render the Scene";
    
    [self drawSence:view commandBuffer:commandBuffer];
  
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)drawSence:(MTKView *)view commandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    MTLRenderPassDescriptor *descriptor = view.currentRenderPassDescriptor;
    
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    [encoder setRenderPipelineState:_pipelineState];
    // 设置数据
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [encoder setFragmentTexture:_texture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
}

- (nonnull AAPLImage*)renderAndReadPixelsFromView:(nonnull MTKView*)view withRegion:(CGRect)region
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    // Encode a render pass to render the image to the drawable texture.
    [self drawSence:view commandBuffer:commandBuffer];
    
    _drewSceneForReadThisFrame = YES;
    id<MTLTexture> readTexture = view.currentDrawable.texture;
    MTLOrigin readOrigin = MTLOriginMake(region.origin.x, region.origin.y, 0);
    MTLSize readSize = MTLSizeMake(region.size.width, region.size.height, 1);
    
    const id<MTLBuffer> pixelBuffer = [self readPixelsWithCommandBuffer:commandBuffer
                                                            fromTexture:readTexture
                                                               atOrigin:readOrigin
                                                               withSize:readSize];

    AAPLPixelBGRA8Unorm *pixels = (AAPLPixelBGRA8Unorm *)pixelBuffer.contents;

#if AAPL_PRINT_PIXELS_READ
    // Process the pixel data.
    printf("Pixels read: wh[%d %d] at xy[%d %d].\n",
        (int)readSize.width, (int)readSize.height,
        (int)readOrigin.x,   (int)readOrigin.y);

    AAPLPixelBGRA8Unorm *row = pixels;

    for (int yy = 0;  yy < readSize.height;  yy++)
    {
        for (int xx = 0;  xx < MIN(5, readSize.width);  xx++)
        {
            unsigned int pixel = *(unsigned int *)&row[xx];
            printf("[%4d=x, %4d=y] x%8X\n", (int)readOrigin.x + xx, (int)readOrigin.y + yy, pixel);
        }
        printf("\n");
        row += readSize.width;  // Advance to the next row.
    }
#endif

    // Create an `NSData` object and initialize it with the pixel data.
    // Use the CPU to copy the pixel data from the `pixelBuffer.contents`
    // pointer to `data`.
    NSData *data = [[NSData alloc] initWithBytes:pixels length:pixelBuffer.length];

    // Create a new image from the pixel data.
    AAPLImage *image = [[AAPLImage alloc] initWithBGRA8UnormData:data
                                                           width:readSize.width
                                                          height:readSize.height];

    return image;
}

//------------------------------------------------------------------------------

// The sample only supports the `MTLPixelFormatBGRA8Unorm` and
// `MTLPixelFormatR32Uint` formats.
static inline uint32_t sizeofPixelFormat(NSUInteger format)
{
    return ((format) == MTLPixelFormatBGRA8Unorm ? 4 :
            (format) == MTLPixelFormatR32Uint    ? 4 : 0);
}

- (id<MTLBuffer>)readPixelsWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                 fromTexture:(id<MTLTexture>)texture
                                    atOrigin:(MTLOrigin)origin
                                    withSize:(MTLSize)size
{
    MTLPixelFormat pixelFormat = texture.pixelFormat;
    switch (pixelFormat)
    {
        case MTLPixelFormatBGRA8Unorm:
        case MTLPixelFormatR32Uint:
            break;
        default:
            NSAssert(0, @"Unsupported pixel format: 0x%X.", (uint32_t)pixelFormat);
    }

    // Check for attempts to read pixels outside the texture.
    // In this sample, the calling code validates the region, so just assert.
    NSAssert(origin.x >= 0, @"Reading outside the left texture bounds.");
    NSAssert(origin.y >= 0, @"Reading outside the top texture bounds.");
    NSAssert((origin.x + size.width)  < texture.width,  @"Reading outside the right texture bounds.");
    NSAssert((origin.y + size.height) < texture.height, @"Reading outside the bottom texture bounds.");

    NSAssert(!((size.width == 0) || (size.height == 0)), @"Reading zero-sized area: %dx%d.", (uint32_t)size.width, (uint32_t)size.height);

    NSUInteger bytesPerPixel = sizeofPixelFormat(texture.pixelFormat);
    NSUInteger bytesPerRow   = size.width * bytesPerPixel;
    NSUInteger bytesPerImage = size.height * bytesPerRow;

    _readBuffer = [texture.device newBufferWithLength:bytesPerImage options:MTLResourceStorageModeShared];

    NSAssert(_readBuffer, @"Failed to create buffer for %zu bytes.", bytesPerImage);

    // Copy the pixel data of the selected region to a Metal buffer with a shared
    // storage mode, which makes the buffer accessible to the CPU.
    id <MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];

    [blitEncoder copyFromTexture:texture
                     sourceSlice:0
                     sourceLevel:0
                    sourceOrigin:origin
                      sourceSize:size
                        toBuffer:_readBuffer
               destinationOffset:0
          destinationBytesPerRow:bytesPerRow
        destinationBytesPerImage:bytesPerImage];

    [blitEncoder endEncoding];

    [commandBuffer commit];
    
    // The app must wait for the GPU to complete the blit pass before it can
    // read data from _readBuffer.
    [commandBuffer waitUntilCompleted];

    // Calling waitUntilCompleted blocks the CPU thread until the blit operation
    // completes on the GPU. This is generally undesirable as apps should maximize
    // parallelization between CPU and GPU execution. Instead of blocking here, you
    // could process the pixels in a completion handler using:
    //      [commandBuffer addCompletedHandler:...];



    return _readBuffer;
}

@end
