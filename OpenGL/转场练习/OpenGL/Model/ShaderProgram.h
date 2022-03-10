//
//  ShaderProgram.h
//  OpenGL
//
//  Created by 任迅 on 2022/3/8.
//

#import <Foundation/Foundation.h>



union Vec2
{
    struct
    {
        float x, y;
    };
    struct
    {
        float r, g;
    };
};


union Vec3
{
    struct
    {
        float x, y ,z;
    };
    struct
    {
        float r, g, b;
    };
};


union Vec4
{
    struct
    {
        float x, y , z, w;
    };
    struct
    {
        float r, g, b, a;
    };
};


typedef union Vec3 Vec3;

NS_ASSUME_NONNULL_BEGIN

@interface ShaderProgram : NSObject

@property (nonatomic, assign) uint32_t programID;

- (void)use;

- (uint32_t)findLocation:(NSString *)key;

- (void)bindVec2:(NSString *)key value:(Vec2)value;

- (void)bindVec3:(NSString *)key value:(Vec3)value;

- (void)bindVec4:(NSString *)key value:(Vec4)value;

@end

NS_ASSUME_NONNULL_END


// MARK: -  glm 的拓展
#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShaderProgram (GLM)


- (void)glm_bindVec2:(NSString *)key value:(glm::vec2)value;
- (void)glm_bindVec3:(NSString *)key value:(glm::vec3)value;
- (void)glm_bindVec4:(NSString *)key value:(glm::vec4)value;

- (void)glm_bindMatrix4x4:(NSString *)key value:(glm::mat4x4)value;
- (void)glm_bindMatrix4x4:(NSString *)key ptr:(const GLfloat*)value;


@end

NS_ASSUME_NONNULL_END
