//
//  ViewController.m
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#import "ViewController.h"
#import "Render/Renderer.h"

@import MetalKit;

@implementation ViewController
{
    Renderer* _render;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    MTKView *mtView = (MTKView *)self.view;
    mtView.device = MTLCreateSystemDefaultDevice();
    
    _render = [[Renderer alloc] initWithMTKView:mtView];
    mtView.delegate = _render;
    
    BOOL supportICB;
#if TARGET_IOS
    supportICB = [mtView.device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v4];
#else
    supportICB = [mtView.device supportsFeatureSet:MTLFeatureSet_macOS_GPUFamily2_v1];
#endif
    NSLog(@"supportICB: %d", supportICB);
}

@end
