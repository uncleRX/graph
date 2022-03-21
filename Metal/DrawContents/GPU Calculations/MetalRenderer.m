//
//  MetalRenderer.m
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/21.
//

#import "MetalRenderer.h"

@implementation MetalRenderer
{
    id<MTLDevice> _device;

    id<MTLCommandQueue> _commandQueue;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    if (self = [super init])
    {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
    }
    return self;
}


//MARK: MTKViewDelegate

// 每一帧渲染的时候会调用
- (void)drawInMTKView:(MTKView *)view
{
    // 您需要创建一个渲染通道，它是绘制到一组纹理中的一系列渲染命令。在渲染过程中使用时，纹理也称为渲染目标。要创建渲染通道，您需要一个渲染通道描述符
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor)
    {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncode = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncode endEncoding];
    
    // 绘制到纹理不会自动在屏幕上显示新内容。实际上，屏幕上只能呈现一些纹理。在 Metal 中，可以在屏幕上显示的纹理由可绘制对象管理，并且要显示内容，您需要呈现可绘制对象。
     // MTKView自动创建可绘制对象来管理其纹理。读取该属性以获取拥有作为渲染通道目标的纹理的可绘制对象。视图返回一个对象，一个连接到 Core Animation 的对象。currentDrawable CAMetalDrawable
    id<MTLDrawable> drawable = view.currentDrawable;
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

/// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

@end
