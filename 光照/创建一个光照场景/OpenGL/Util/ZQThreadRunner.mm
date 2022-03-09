//
//  ZQThreadRunner.m
//  venus-ios
//
//  Created by ylin on 2018/12/28.
//  Copyright © 2018 bhb. All rights reserved.
//

#import "ZQThreadRunner.h"
#import "ZQWeakProxy.h"

@interface ZQThreadRunner ()
@property (strong, nonatomic) NSMutableArray <ZQThreadRunnerBlock> *runTasks;
@property (strong, nonatomic) NSThread  *innerThread;
@property (strong, nonatomic) NSPort    *port;
@property (strong, nonatomic) CADisplayLink *timer;
@property (assign, atomic) BOOL runnable;
@property (assign, atomic) BOOL timerStart;
@property (assign, nonatomic) BOOL isLoop;

@end

@implementation ZQThreadRunner

- (void)dealloc {
    NSLog(@"ZQThreadRunner dealloc");
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)cancel {
    
    [self performSelector:@selector(removePort)
                 onThread:self.innerThread
               withObject:nil
            waitUntilDone:false];

}

+ (instancetype)buildRunner {
    
    return [self buildRunnerWithThread:nil];
}

+ (instancetype)buildRunnerWithThread:(NSThread * _Nullable)thread {
    ZQThreadRunner *ins = [[ZQThreadRunner alloc] init];
    [ins _initContent:thread];
    return ins;
}

- (void)_initTimeLauncher {
    self.timer = [CADisplayLink displayLinkWithTarget:[ZQWeakProxy proxyWithTarget:self]
                                             selector:@selector(_timerAction:)];
    [self.timer addToRunLoop:[NSRunLoop currentRunLoop]
                     forMode:NSRunLoopCommonModes];
    [self updateFps];
    self.fps = 60;
    [self.timer setPaused:!self.timerStart];
}

/**
 初始化

 @param thread 如果需要使用外部管理的线程, 则使用该参数, 否则该参数为空, 内部构造线程
 */
- (void)_initContent:(NSThread *)thread {
    
    self.runTasks = [NSMutableArray array];
    if (thread) {
        self.innerThread = thread;
    } else {
        
        self.innerThread = [[NSThread alloc]
                            initWithTarget:[ZQWeakProxy proxyWithTarget:self]
                            selector:@selector(startRunloop)
                            object:nil];
        [self.innerThread start];
    }
}

- (void)startRunloop {

    @autoreleasepool {
        
        [self _initTimeLauncher];
        
        NSRunLoop *loop  = [NSRunLoop currentRunLoop];
        self.port = [NSMachPort port];
        [loop addPort:self.port forMode:NSDefaultRunLoopMode];
        
        self.isLoop = true;
        
        while (self.isLoop &&
               [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
        {
            
        }
    }
}

- (NSThread *)thread {
    return self.innerThread;
}

- (void)_timerAction:(CADisplayLink *)timer
{
    // 防止线程问题
    if (!self.timerStart)
    {
        return;
    }
    if (self.timerAction) {
        self.timerAction();
    }
}

- (void)start
{
    self.timerStart = true;
    [self.timer setPaused:false];
}

- (void)stop {
    if (self.timer.isPaused) {
        return;
    }
    [self performSelector:@selector(_waitAndStop) onThread:self.innerThread withObject:nil waitUntilDone:YES];
}

- (void)_waitAndStop {
    self.timerStart = false;
    [self.timer setPaused:true];
}

- (void)setFps:(float)fps {
    _fps = fps;
    [self updateFps];
}

- (void)updateFps
{
    if (@available(iOS 10.0, *)) {
        //一秒刷新次数
        self.timer.preferredFramesPerSecond = (NSInteger)self.fps;
    } else {
        // 屏幕刷新间隔数
        self.timer.frameInterval = NSInteger (30.0 / self.fps);
    }
}

- (BOOL)addRunner:(ZQThreadRunnerBlock)runner {
    [self.runTasks addObject:runner];

    [self run];
    return true;
}

- (void)run {
    /// 没有任务
    if (self.runTasks.count == 0) {
        self.runnable = false;
        return;
    }
    /// 正在执行
    if (self.runnable) {
        return;
    }
    self.runnable = true;
    [self performSelector:@selector(execInThread:)
                 onThread:self.innerThread
               withObject:nil
            waitUntilDone:false];
}

- (ZQThreadRunnerBlock)popRunner
{
    ZQThreadRunnerBlock action = self.runTasks.firstObject;
    [self.runTasks removeObject:action];
    return action;
}

- (void)execInThread:(id)sender {
    ZQThreadRunnerBlock action = [self popRunner];
    while (action) {
        action();
        action = [self popRunner];
    }
    self.runnable = false;
    [self run];
}

- (void)removePort
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    [self.timer removeFromRunLoop:runLoop
                          forMode:NSRunLoopCommonModes];
    [self.timer invalidate];
    self.timer = nil;
    
    self.isLoop = NO;
    [runLoop removePort:self.port forMode:NSDefaultRunLoopMode];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
