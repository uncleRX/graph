//
//  MetalRenderer.h
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@import MetalKit;

@interface MetalRenderer : NSObject<MTKViewDelegate>

- (instancetype)initWithMetalKitView:(MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
