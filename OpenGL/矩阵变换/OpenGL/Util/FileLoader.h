//
//  FileLoader.h
//  OpenGL
//
//  Created by 任迅 on 2021/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageFile : NSObject

@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;
@property (nonatomic, assign) uint8_t* byte;

@end

@interface FileLoader : NSObject

+ (ImageFile *)loadImage:(NSString *)name type:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
