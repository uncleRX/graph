//
//  ViewController.m
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/10.
//

#import "ViewController.h"
#import <Metal/Metal.h>
#import "MetalRenderer.h"

@interface ViewController ()

@end

@implementation ViewController
{
    MTKView *_view;
    MetalRenderer *_render;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _view = (MTKView *)self.view;
    _view.enableSetNeedsDisplay = YES;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0);
    
    _render = [[MetalRenderer alloc] initWithMetalKitView:_view];
    _view.delegate = _render;
    // 设置尺寸
    [_render mtkView:_view drawableSizeWillChange:_view.drawableSize];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
