//
//  CGLView.m
//  OpenGL
//
//  Created by 任迅 on 2021/9/14.
//

#import "CGLView.h"

@implementation CGLView

+(Class) layerClass {
    return [CAEAGLLayer class];
}

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.layer.opaque = YES;
    self.layer.contentsScale = [[UIScreen mainScreen] scale];
    ((CAEAGLLayer *)self.layer).drawableProperties =
        [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
         kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,
         kEAGLDrawablePropertyColorFormat, nil];
    
    return self;
}

- (instancetype) initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.layer.opaque = YES;
    self.layer.contentsScale = [[UIScreen mainScreen] scale];
    ((CAEAGLLayer *)self.layer).drawableProperties =
            [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                                       kEAGLDrawablePropertyRetainedBacking,
                                                       kEAGLColorFormatRGBA8,
                                                       kEAGLDrawablePropertyColorFormat, nil];
    return self;
}


@end
