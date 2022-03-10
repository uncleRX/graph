//
//  FileLoader.m
//  OpenGL
//
//  Created by 任迅 on 2021/9/16.
//

#import "FileLoader.h"
#import <UIKit/UIKit.h>

@implementation ImageFile

@end

@implementation FileLoader

+ (ImageFile *)loadImage:(NSString *)name type:(NSString *)type {
    
    ImageFile *file = [[ImageFile alloc] init];
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    NSData *textureData = [NSData dataWithContentsOfFile:path];
    UIImage *img = [UIImage imageWithData:textureData];
    file.width  = CGImageGetWidth(img.CGImage);
    file.height = CGImageGetHeight(img.CGImage);
    CGImageRef cgImage = img.CGImage;
    CFDataRef provider  = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    file.byte = CFDataGetBytePtr(provider);
    return file;
}

@end
