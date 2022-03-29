//
//  DefineTypes.h
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#ifndef DefineTypes_h
#define DefineTypes_h

#include <simd/simd.h>

typedef struct VertextObject {
    // 位置
    vector_float2 position;
    // 纹理坐标
    vector_float2 texCoord;
}VertextObject;

typedef struct AAPLVertex
{
    // Positions of the shader input vertices.
    vector_float2 position;

    // Floating point RGBA colors.
    vector_float4 color;
} AAPLVertex;


typedef enum VertextInputIndex
{
    VertextInputIndexVertices = 0,
}VertextInputIndex;


#endif /* DefineTypes_h */
