//
//  GLESUtil.m
//  OpenGL
//
//  Created by 任迅 on 2021/9/14.
//

#import "GLESUtil.h"
#include "stb_image.h"
#import "ImageHelper.h"

@implementation GLESUtil

+ (GLuint)creatShaderProgramWithVertextShaderName:(NSString *)vertexName
                              fragmentShaderName:(NSString *)fragmentName {
    GLuint vertexShader = [self creatShader:GL_VERTEX_SHADER fileName:vertexName];
    GLuint fragmentShader = [self creatShader:GL_FRAGMENT_SHADER fileName:fragmentName];
    // 创建着色器程序
    GLuint shaderProgram;
    shaderProgram = glCreateProgram();
    // 将着色器附加到着色器程序上
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);
    int success = 0;
    // 检测是否链接成功
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if(!success) {
        printf("链接着色器程序失败");
    }
    // 删除不用的着色器
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    return shaderProgram;
}

+ (GLuint)creatShader:(GLenum)type fileName:(NSString *)fileName {
    unsigned int shader;
    shader = glCreateShader(type);
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:@"glsl"];
    NSError *error;
    NSString *pathContent = [NSString stringWithContentsOfFile:path encoding:(NSUTF8StringEncoding) error:&error];
    const char *shaderSource = pathContent.UTF8String;
    glShaderSource(shader, 1, &shaderSource, NULL);
    // 编译着色器
    glCompileShader(shader);
    // 检测着色器是否编译成功
    GLint success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        printf(infoLog);
    }
    return shader;
}

+ (GLuint)genTexture:(int)index format:(int)pixelFormat filePath:(NSString *)path
{
    GLuint texture;
    glGenTextures(1, &texture);
    // 绑定之前需要先激活
    glActiveTexture(GL_TEXTURE0 + index);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    // 为当前绑定的纹理对象设置环绕、过滤方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 1 - 生成纹理
    int imageWidth, imageHeight, imageChannels;
    stbi_set_flip_vertically_on_load(true);
    stbi_convert_iphone_png_to_rgb(true);
    unsigned char *imageData = stbi_load(path.UTF8String, &imageWidth, &imageHeight, &imageChannels, STBI_rgb_alpha);
    if (imageData)
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
        glGenerateMipmap(GL_TEXTURE_2D);
        stbi_image_free(imageData);
    }
    else
    {
        NSLog(@"加载素材失败");
    }
    return texture;
}

@end
