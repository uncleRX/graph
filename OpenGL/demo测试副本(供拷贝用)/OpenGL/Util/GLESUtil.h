//
//  GLESUtil.h
//  OpenGL
//
//  Created by 任迅 on 2021/9/14.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import "TextureModel.h"

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>

NS_ASSUME_NONNULL_BEGIN

typedef enum ContentMode
{
    ContentModeRaw = 1,   ///< 锚点原点在中心，位置在合成中心， 原始尺寸 .
    ContentModeScaleToFill = 2,   ///< 锚点原点在中心，位置在合成中心， 平铺充满, 内容会有拉伸 .
    ContentModeScaleAspectFit = 3,   ///< 锚点原点在中心，位置在合成中心，内容会全部显示, 会有上下或者左右空白 .
    ContentModeScaleAspectFill = 4    ///< 锚点原点在中心，位置在合成中心，内容缩放充满容器, 内容可能不完全显示 .
}ContentMode;

@interface GLESUtil : NSObject

+ (GLuint)creatShaderProgramWithVertextShaderName:(NSString *)vertexName
                              fragmentShaderName:(NSString *)fragmentName;

+ (GLuint)creatShader:(GLenum)type fileName:(NSString *)fileName;

+ (nullable TextureModel *)genTexture:(int)index format:(int)pixelFormat filePath:(NSString *)path;

+ (glm::vec2)getScale:(ContentMode)mode sourceSize:(CGSize)sw targetSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
