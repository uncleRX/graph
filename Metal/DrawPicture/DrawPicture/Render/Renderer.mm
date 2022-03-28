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
    id <MTLTexture> _texture;
    id <MTLBuffer> _vertexBuffer; // 纹理数据
}

- (void)setPipleLine:(MTKView * _Nonnull)view {
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

- (instancetype)initWithMTKView:(MTKView *)view
{
    if (self = [super init])
    {
        _device = view.device;
        _commandQueue = [_device newCommandQueue];
        [self setupBuffers];
        [self setPipleLine:view];
        [self setupTexture];
    }
    return self;
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
//    NSImage *img = [NSImage imageNamed:@"lena"];
    NSImage *img = [NSImage imageNamed:@"wallhaven-3kvqm9"];

//   _texture = [self newTextureWithImage:img];
//    int imageWidth, imageHeight, imageChannels;
//    stbi_set_flip_vertically_on_load(true);
//    stbi_convert_iphone_png_to_rgb(true);
//    unsigned char *imageData = stbi_load(path.UTF8String, &imageWidth, &imageHeight, &imageChannels, STBI_rgb_alpha);
//
//    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
//    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
//    textureDescriptor.width = imageWidth;
//    textureDescriptor.height = imageHeight;
//    id<MTLTexture> texture = [_device newTextureWithDescriptor:textureDescriptor];
//
//    NSUInteger bytesPerRow = 4 * imageWidth;
//    MTLRegion region = {
//                        {0, 0, 0}, //原点
//                        {(NSUInteger)imageWidth, (NSUInteger)imageHeight, 1} //size
//                        };
//    [texture replaceRegion:region
//                    mipmapLevel:0
//                      withBytes:imageData
//                    bytesPerRow:bytesPerRow];
    
    _texture = [self newTextureWithImage:img];
}

- (id<MTLTexture>)newTextureWithImage:(NSImage *)image {
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
    id<MTLTexture> texture = [_device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    
    free(rawData);
    
    return texture;
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
    MTLRenderPassDescriptor *descriptor = view.currentRenderPassDescriptor;
    descriptor.colorAttachments[0].texture = drawable.texture;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    [encoder setRenderPipelineState:_pipelineState];
  
    // 设置数据
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
//    [encoder setVertexBytes:&quadVertices length:sizeof(quadVertices) atIndex:VertextInputIndexVertices];
    [encoder setFragmentTexture:_texture atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
