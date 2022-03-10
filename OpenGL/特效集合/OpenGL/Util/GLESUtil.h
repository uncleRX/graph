//
//  GLESUtil.h
//  OpenGL
//
//  Created by 任迅 on 2021/9/14.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import "TextureModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLESUtil : NSObject

+ (GLuint)creatShaderProgramWithVertextShaderName:(NSString *)vertexName
                              fragmentShaderName:(NSString *)fragmentName;

+ (GLuint)creatShader:(GLenum)type fileName:(NSString *)fileName;

+ (nullable TextureModel *)genTexture:(int)index format:(int)pixelFormat filePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
