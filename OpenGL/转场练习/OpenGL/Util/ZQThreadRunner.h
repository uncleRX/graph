//
//  ZQThreadRunner.h.h
//  venus-ios
//
//  Created by ylin on 2018/12/28.
//  Copyright © 2018 bhb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

typedef void(^ZQThreadRunnerBlock)(void);
NS_ASSUME_NONNULL_BEGIN

@interface ZQThreadRunner : NSObject

/// 默认构造方法不可用
-(instancetype) init __attribute__((unavailable("使用 +builderRunner 代替")));
+(instancetype) new __attribute__((unavailable("使用 +builderRunner 代替")));

@property (strong, nonatomic, readonly) NSThread *thread;
@property (strong, nonatomic, readonly) CADisplayLink *timer;
@property (copy, nonatomic) ZQThreadRunnerBlock timerAction;
/// 自然速度绘制的帧率, 默认60
@property (nonatomic, assign) float fps;

/// 构建
+ (instancetype)buildRunner;
+ (instancetype)buildRunnerWithThread:( NSThread * _Nullable )thread;

// 启动定时回调
- (void)start;
- (void)stop;

/// 添加一个执行动作
- (BOOL)addRunner:(ZQThreadRunnerBlock)renner;
/// 取消线程
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
