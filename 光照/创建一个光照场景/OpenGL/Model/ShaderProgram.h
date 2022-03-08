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
