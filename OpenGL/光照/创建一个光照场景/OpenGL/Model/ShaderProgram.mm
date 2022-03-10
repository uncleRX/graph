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


@implementation ShaderProgram (GLM)

- (void)glm_bindVec2:(NSString *)key value:(glm::vec2)value
{
    glUniform2f([self findLocation:key], value.x, value.y);
}

- (void)glm_bindVec3:(NSString *)key value:(glm::vec3)value
{
    glUniform3f([self findLocation:key], value.x, value.y, value.z);
}

- (void)glm_bindVec4:(NSString *)key value:(glm::vec4)value
{
    glUniform4f([self findLocation:key], value.x, value.y, value.z, value.w);
}

- (void)glm_bindMatrix4x4:(NSString *)key value:(glm::mat4x4)value
{
    [self glm_bindMatrix4x4:key ptr:glm::value_ptr(value)];
}

- (void)glm_bindMatrix4x4:(NSString *)key ptr:(const GLfloat*)value
{
    glUniformMatrix4fv([self findLocation:key], 1, GL_FALSE, value);
}

@end




