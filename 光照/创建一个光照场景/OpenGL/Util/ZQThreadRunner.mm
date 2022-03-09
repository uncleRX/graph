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
        [self _initTimeLauncher];
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
    return ins;
}

- (void)_initTimeLauncher {
    self.timer = [CADisplayLink displayLinkWithTarget:[ZQWeakProxy proxyWithTarget:self]
                                             selector:@selector(_timerAction:)];
    [self.timer addToRunLoop:[NSRunLoop currentRunLoop]
                     forMode:NSRunLoopCommonModes];
    [self updateFps];
    self.fps = 30;
    [self.timer setPaused:true];
}

- (NSThread *)thread {
    return self.innerThread;
}

- (void)_timerAction:(CADisplayLink *)timer
{
    // 防止线程问题
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
    [self _waitAndStop];
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
        self.timer.frameInterval = NSInteger (6.0 / self.fps);
    }
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
