//
//  Shaders.metal
//  GPU Calculations
//
//  Created by 任迅 on 2022/3/21.
//

#include <metal_stdlib>

#include "ShaderTypes.h"

using namespace metal;

// 先绘制一个三角形

// Vertex shader outputs and fragment shader inputs
struct RasterizerData
{
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]])
{
    RasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = vertices[vertexID].position.xy;
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}


#pragma mark -

#pragma mark 临时纹理渲染到屏幕

struct TexturePipelineRasterizerData
{
    float4 position [[position]];
    float2 texcoord;
};

vertex TexturePipelineRasterizerData
textureVertextShader(uint vertextID [[vertex_id]],
                     const device TextureVertex *vertices [[ buffer(VertexInputIndexVertices) ]],
                     constant float &aspectRatio [[ buffer(VertexInputIndexAspectRatio) ]])
{
    TexturePipelineRasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.x = vertices[vertextID].position.x * aspectRatio;
    out.position.y = vertices[vertextID].position.y;
    out.texcoord = vertices[vertextID].texcoord;
    return out;
}

fragment float4 textureFragmentShader(TexturePipelineRasterizerData in [[stage_in]],
                                      texture2d<float> texture [[texture(TextureInputIndexColor)]]
                                      )

{
    // 采样器
    sampler sampler;
    float4 colorSample = texture.sample(sampler, in.texcoord);
    return colorSample;
}
