//
//  MetalRenderer.m
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/21.
//

#import "MetalRenderer.h"
#import "ShaderTypes.h"

@implementation MetalRenderer
{
    id<MTLDevice> _device;

    id<MTLCommandQueue> _commandQueue;
    
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLRenderPipelineState> _renderToTexturePipelineState;

    // 用作顶点着色器的输入
    vector_uint2 _viewportSize;
    
    id <MTLTexture> _renderTargetTexture;
    
    MTLRenderPassDescriptor *_renderToTextureRenderPassDescriptor;
    
    float _aspectRatio;

    
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    if (self = [super init])
    {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
        
        
        mtkView.clearColor = MTLClearColorMake(0.0, 1.0, 0.0, 1.0);
        // 创建一个临时纹理
        
        MTLTextureDescriptor *texDescriptor = [MTLTextureDescriptor new];
        texDescriptor.textureType = MTLTextureType2D;
        texDescriptor.width = 520;
        texDescriptor.height = 520;
        texDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
        texDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        _renderTargetTexture = [_device newTextureWithDescriptor:texDescriptor];
        
        // 配置渲染通道描述符 描述渲染過程
        _renderToTextureRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _renderToTextureRenderPassDescriptor.colorAttachments[0].texture = _renderTargetTexture;
        _renderToTextureRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderToTextureRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
        _renderToTextureRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        // 設置renderPass;
        // load shader
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        
        NSError *error;
        
        // 配置渲染到屏幕
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"渲染到屏幕";
        pipelineStateDescriptor.sampleCount = mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction = [defaultLibrary newFunctionWithName:@"textureVertextShader"];
        pipelineStateDescriptor.fragmentFunction = [defaultLibrary newFunctionWithName:@"textureFragmentShader"];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.vertexBuffers[VertexInputIndexVertices].mutability = MTLMutabilityImmutable;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

        pipelineStateDescriptor.label = @"离屏渲染管线";
        // 附件如果不支持多重采样. 默认就是1
        pipelineStateDescriptor.sampleCount = 1;
        id <MTLFunction> func1 = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id <MTLFunction> func2 = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        pipelineStateDescriptor.vertexFunction = func1;
        pipelineStateDescriptor.fragmentFunction = func2;
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture.pixelFormat;

        _renderToTexturePipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        
        // 如果pipel描述符没有正确设置, 则PipelineState可能创建失败
        NSAssert(_renderToTexturePipelineState, @"Failed to create pipeline state: %@", error);
    }
    return self;
}


//MARK: MTKViewDelegate

// 每一帧渲染的时候会调用
- (void)drawInMTKView:(MTKView *)view
{
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    {
        
        // 渲染到纹理
        static const Vertex triangleVertices[] =
        {
            // 2D positions       RGBA colors
            { { 0.5, -0.5}, {1, 0, 0, 1} },
            { { -0.5,  -0.5 }, { 0, 1, 0, 1 } },
            { {    0.0,   0.5 }, { 0, 0, 1, 1 } },
        };
        
        MTLRenderPassDescriptor *renderPassDescriptor = _renderToTextureRenderPassDescriptor;
        if (renderPassDescriptor != nil)
        {
           id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            renderEncoder.label = @"offscreen Render pass";
            [renderEncoder setRenderPipelineState:_renderToTexturePipelineState];
            // 设置顶点数据
            [renderEncoder setVertexBytes:triangleVertices length:sizeof(triangleVertices) atIndex:VertexInputIndexVertices];
            // 绘制三角形
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
            [renderEncoder endEncoding];
        }
    }
    
    MTLRenderPassDescriptor *drawableRenderPassDescriptor = view.currentRenderPassDescriptor;
    if(drawableRenderPassDescriptor != nil)
    {
        static const TextureVertex quadVertices[] =
        {
            // Positions     , Texture coordinates
            { {  0.5,  -0.5 },  { 1.0, 1.0 } },
            { { -0.5,  -0.5 },  { 0.0, 1.0 } },
            { { -0.5,   0.5 },  { 0.0, 0.0 } },

            { {  0.5,  -0.5 },  { 1.0, 1.0 } },
            { { -0.5,   0.5 },  { 0.0, 0.0 } },
            { {  0.5,   0.5 },  { 1.0, 0.0 } },
        };
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:drawableRenderPassDescriptor];
        renderEncoder.label = @"Drawable Render Pass";

        [renderEncoder setRenderPipelineState:_pipelineState];

        [renderEncoder setVertexBytes:&quadVertices
                               length:sizeof(quadVertices)
                              atIndex:VertexInputIndexVertices];

        [renderEncoder setVertexBytes:&_aspectRatio
                               length:sizeof(_aspectRatio)
                              atIndex:VertexInputIndexAspectRatio];

        // Set the offscreen texture as the source texture.
        [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:TextureInputIndexColor];

        // Draw quad with rendered texture.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    
    // 4. 指定渲染目标(纹理) 绘制到哪里去, 这里连接的是 core Animation 的对象。currentDrawable CAMetalDrawable
    [commandBuffer presentDrawable:view.currentDrawable];

    // 5. 提交指令
    [commandBuffer commit];
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _aspectRatio =  (float)size.height / (float)size.width;

}

@end
