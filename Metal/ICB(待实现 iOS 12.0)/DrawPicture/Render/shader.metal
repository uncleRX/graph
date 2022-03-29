//
//  shader.metal
//  DrawPicture
//
//  Created by 任迅 on 2022/3/25.
//

#include <metal_stdlib>
#include "DefineTypes.h"

using namespace metal;

struct RasterizaData
{
    // 顶点位置
    float4 position [[position]];
    
    // 纹理坐标
    float2 texCoord;
};

vertex RasterizaData
vertextShader(uint vertextID [[ vertex_id ]],
              const device VertextObject* vertices [[ buffer(VertextInputIndexVertices) ]])
{
    RasterizaData out;
    out.position = float4(0.0, 0.0, 1.0,1.0);
    out.position.xy = vertices[vertextID].position.xy;
    out.texCoord = vertices[vertextID].texCoord;
    return out;
}

fragment float4
fragmentShader(RasterizaData in [[ stage_in ]],
               texture2d<float> tex2d [[texture(0)]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    return float4(tex2d.sample(textureSampler, in.texCoord));
}
