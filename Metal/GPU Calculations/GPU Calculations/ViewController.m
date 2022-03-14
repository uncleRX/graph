//
//  ViewController.m
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/10.
//

#import "ViewController.h"
#import <Metal/Metal.h>
#import "MetalAdder.h"

@interface ViewController ()

@property (nonatomic, strong) MetalAdder *adder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.adder = [[MetalAdder alloc] initWithDevice:MTLCreateSystemDefaultDevice()];
    [self.adder prepareData];
    [self.adder sendComputeCommand];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
