//
//  Renderer.h
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject <MTKViewDelegate>

- (instancetype)initWithMTKView:(MTKView *)view;

@end

NS_ASSUME_NONNULL_END
