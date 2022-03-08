//
//  TextureModel.h
//  OpenGL
//
//  Created by 任迅 on 2022/3/3.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextureModel : NSObject

@property (nonatomic, assign) NSUInteger textureID;

@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;

- (CGSize)size;

@end

NS_ASSUME_NONNULL_END
