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



//MARK: - 计算函数
// Rec. 709 luma values for grayscale image conversion
constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);


kernel void
grayscaleKernel(texture2d<half, access::read> inTexture [[ texture(0)]],
                texture2d<half, access::write> outTexture [[ texture(1)]],
                uint2 gid [[thread_position_in_grid]])
{
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, kRec709Luma);
    outTexture.write(half4(gray, gray, gray, 1.0), gid);
}
