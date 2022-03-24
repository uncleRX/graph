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
    
    // 用作顶点着色器的输入
    vector_uint2 _viewportSize;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    if (self = [super init])
    {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
        
        // load shader
        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        id<MTLFunction> vertextFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        // Configure pipeline descriptor
        

        MTLRenderPipelineDescriptor *pipelStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelStateDescriptor.vertexFunction = vertextFunction;
        pipelStateDescriptor.fragmentFunction = fragmentFunction;
        // 颜色空间
        pipelStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        
        NSError *error;
        _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelStateDescriptor error:&error];
        
        // 如果pipel描述符没有正确设置, 则PipelineState可能创建失败
        NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);
    }
    return self;
}


//MARK: MTKViewDelegate

// 每一帧渲染的时候会调用
- (void)drawInMTKView:(MTKView *)view
{
    // 1. 定义三角形顶点数据
    static const Vertex triangleVertices[] =
    {
        // 2D positions       RGBA colors
        { { 250.0, -250}, {1, 0, 0, 1} },
        { { -250,  -250 }, { 0, 1, 0, 1 } },
        { {    0,   250 }, { 0, 0, 1, 1 } },
    };
    
    // 2. 构建commandBuffer
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    // 3. 设置编码器
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
       id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"RenderEncoder";
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        // 设置绘制区域
        MTLViewport viewPort = {0.0, 0.0, _viewportSize.x, _viewportSize.y, 0.0, 1.0};
        [renderEncoder setViewport:viewPort];
        
        // 设置顶点数据
        [renderEncoder setVertexBytes:triangleVertices length:sizeof(triangleVertices) atIndex:VertexInputIndexVertices];
        // 设置视口数据
        [renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputIndexViewportSize];
        
        // 绘制三角形
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [renderEncoder endEncoding];
    }
    
    // 4. 指定渲染目标(纹理) 绘制到哪里去, 这里连接的是 core Animation 的对象。currentDrawable CAMetalDrawable
    [commandBuffer presentDrawable:view.currentDrawable];

    // 5. 提交指令
    [commandBuffer commit];
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

@end
