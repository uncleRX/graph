//
//  ShaderTypes.h
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/21.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

typedef enum VertexInputIndex
{
    VertexInputIndexVertices = 0,
    VertexInputIndexViewportSize = 1,
}VertexInputIndex;


typedef struct
{
    vector_float2 position;
    vector_float4 color;
}Vertex;






#endif /* ShaderTypes_h */
