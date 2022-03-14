//
//  MetalAdder.h
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/11.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalAdder : NSObject

@property (nonatomic, strong) id<MTLDevice> device;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)prepareData;

- (void)sendComputeCommand;

@end

NS_ASSUME_NONNULL_END
