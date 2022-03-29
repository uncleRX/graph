//
//  Renderer.h
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import "AAPLImage.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct AAPLPixelBGRA8Unorm {
    uint8_t blue;
    uint8_t green;
    uint8_t red;
    uint8_t alpha;
} AAPLPixelBGRA8Unorm;

@interface Renderer : NSObject <MTKViewDelegate>

@property BOOL drawOutline;
@property CGRect outlineRect;


- (instancetype)initWithMTKView:(MTKView *)view;

- (nonnull AAPLImage*)renderAndReadPixelsFromView:(nonnull MTKView*)view withRegion:(CGRect)region;


@end

NS_ASSUME_NONNULL_END
