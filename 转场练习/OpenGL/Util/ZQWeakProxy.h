//
//  ZQWeakProxy.h
//  zhuque
//
//  Created by 任迅 on 2021/10/29.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface ZQWeakProxy : NSProxy

@property (nullable, nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;

+ (instancetype)proxyWithTarget:(id)target;

@end


NS_ASSUME_NONNULL_END
