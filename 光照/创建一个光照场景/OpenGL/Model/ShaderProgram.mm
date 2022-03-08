//
//  ShaderProgram.m
//  OpenGL
//
//  Created by 任迅 on 2022/3/8.
//

#import "ShaderProgram.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@implementation ShaderProgram

- (void)use {
    glUseProgram(self.programID);
}

- (void)bindVec2:(NSString *)key value:(Vec2)value {
    uint32_t l = [self findLocation:key];
    glUniform2f(l, value.x, value.y);
}

- (void)bindVec3:(NSString *)key value:(Vec3)value {
    uint32_t l = [self findLocation:key];
    glUniform3f(l, value.x, value.y, value.z);
}

- (void)bindVec4:(NSString *)key value:(Vec4)value {
    uint32_t l = [self findLocation:key];
    glUniform4f(l, value.x, value.y, value.z, value.z);
}

- (uint32_t)findLocation:(NSString *)key {
    return glGetUniformLocation(GLuint(self.programID), key.UTF8String);
}

@end
